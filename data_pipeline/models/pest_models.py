"""
Pest Degree-Day models for FarmSmart.

Each pest has a known base temperature and degree-day threshold.
We accumulate daily heat units from season start.
When accumulated DD approaches the threshold → alert is triggered.
"""

import logging
from utils.constants import PEST_CONFIG, DD_RISK_HIGH, DD_RISK_MEDIUM, DD_RISK_LOW

logger = logging.getLogger(__name__)


class PestModel:
    """
    Stateful degree-day accumulator for a single pest.

    Usage:
        model = PestModel.from_config('fall_armyworm')
        for tmax, tmin in daily_temps:
            result = model.add_daily_reading(tmax, tmin)
        print(result['risk_level'])
    """

    def __init__(self, name: str, base_temp_c: float, dd_threshold: float):
        self.name         = name
        self.base_temp    = base_temp_c
        self.dd_threshold = dd_threshold
        self.accumulated  = 0.0
        self.generations  = 0

    @classmethod
    def from_config(cls, pest_id: str) -> "PestModel":
        cfg = PEST_CONFIG[pest_id]
        return cls(
            name=cfg["name"],
            base_temp_c=cfg["base_temp"],
            dd_threshold=cfg["dd_threshold"],
        )

    @classmethod
    def from_state(
        cls, pest_id: str, accumulated: float, generations: int
    ) -> "PestModel":
        """Restore a model from persisted database state."""
        model = cls.from_config(pest_id)
        model.accumulated = accumulated
        model.generations = generations
        return model

    def add_daily_reading(self, tmax: float, tmin: float) -> dict:
        """
        Process one day of temperature data.
        Returns a dict with risk level, progress, and generation count.
        """
        tmean    = (tmax + tmin) / 2
        daily_dd = max(0.0, tmean - self.base_temp)
        self.accumulated += daily_dd

        # Count completed generations (pest resets after each full cycle)
        while self.accumulated >= self.dd_threshold:
            self.accumulated -= self.dd_threshold
            self.generations += 1

        progress = (self.accumulated / self.dd_threshold) * 100

        if progress > DD_RISK_HIGH:
            risk = "HIGH"
        elif progress > DD_RISK_MEDIUM:
            risk = "MEDIUM"
        elif progress > DD_RISK_LOW:
            risk = "LOW"
        else:
            risk = "MINIMAL"

        return {
            "pest":             self.name,
            "daily_dd":         round(daily_dd, 1),
            "accumulated_dd":   round(self.accumulated, 1),
            "threshold":        self.dd_threshold,
            "progress_percent": round(progress, 1),
            "generations":      self.generations,
            "risk_level":       risk,
        }

    def reset_season(self):
        """Reset accumulator for a new growing season."""
        self.accumulated = 0.0
        self.generations = 0


def check_humidity_pest_risk(
    humidity_percent: float, leaf_wetness_hours: int
) -> str:
    """
    Humidity-triggered disease risk (Tomato Late Blight, Rust).
    Used in addition to degree-day accumulation for fungal diseases.
    """
    if humidity_percent > 85 and leaf_wetness_hours > 48:
        return "HIGH"
    elif humidity_percent > 70 and leaf_wetness_hours > 24:
        return "MEDIUM"
    return "LOW"


def build_pest_models() -> dict[str, PestModel]:
    """Instantiate all registered pest models from config."""
    return {pest_id: PestModel.from_config(pest_id) for pest_id in PEST_CONFIG}


# Module-level default instances (used when no persisted state exists)
PEST_MODELS = build_pest_models()
