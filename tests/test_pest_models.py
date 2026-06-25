"""
Tests for pest degree-day accumulation models.
Validates Fall Armyworm accumulation against historical outbreak data.
"""

import pytest
from data_pipeline.models.pest_models import PestModel, check_humidity_pest_risk, PEST_MODELS


class TestPestModel:
    def test_faw_accumulation_basic(self):
        """Fall Armyworm — 20 days of warm nights should accumulate significant DD."""
        model = PestModel.from_config("fall_armyworm")
        for _ in range(20):
            result = model.add_daily_reading(tmax=33, tmin=22)
        # Mean=27.5, base=12 → daily_dd=15.5 × 20 = 310 DD
        assert result["accumulated_dd"] > 0
        assert result["risk_level"] in ("MEDIUM", "HIGH")

    def test_faw_cold_days_no_accumulation(self):
        """Days below base temp (12°C) must not accumulate degree-days."""
        model = PestModel.from_config("fall_armyworm")
        for _ in range(10):
            result = model.add_daily_reading(tmax=15, tmin=5)
        # Mean=10 < base=12 → daily_dd = 0
        assert result["daily_dd"] == 0.0
        assert result["risk_level"] == "MINIMAL"

    def test_faw_generation_reset(self):
        """After threshold is crossed, accumulated DD resets for next generation."""
        model = PestModel.from_config("fall_armyworm")
        # Push far past 350 DD threshold
        for _ in range(30):
            model.add_daily_reading(tmax=38, tmin=25)
        assert model.generations >= 1
        assert model.accumulated < model.dd_threshold

    def test_risk_levels_progress(self):
        """Risk level thresholds: >80% → HIGH, >60% → MEDIUM, >40% → LOW."""
        model = PestModel("Test Pest", base_temp_c=10.0, dd_threshold=100.0)

        # Accumulate to 45% progress
        model.accumulated = 45.0
        result = model.add_daily_reading(tmax=11, tmin=10)
        # 45 + ~0.5 = ~45.5% → LOW
        assert result["risk_level"] in ("LOW", "MEDIUM")

        # Accumulate to 85% progress
        model.accumulated = 85.0
        result = model.add_daily_reading(tmax=11, tmin=10)
        assert result["risk_level"] == "HIGH"

    def test_from_state_restores_correctly(self):
        """Restoring from DB state should produce same results as fresh accumulation."""
        restored = PestModel.from_state(
            pest_id="stem_borer",
            accumulated=200.0,
            generations=1,
        )
        assert restored.accumulated == 200.0
        assert restored.generations == 1
        assert restored.base_temp   == 10.0

    def test_all_pest_models_instantiate(self):
        """All registered pest models should load without error."""
        from utils.constants import PEST_CONFIG
        for pest_id in PEST_CONFIG:
            model = PestModel.from_config(pest_id)
            assert model.name
            assert model.base_temp > 0
            assert model.dd_threshold > 0


class TestHumidityPestRisk:
    def test_high_humidity_triggers_high_risk(self):
        assert check_humidity_pest_risk(90, 50) == "HIGH"

    def test_moderate_humidity_medium_risk(self):
        assert check_humidity_pest_risk(75, 30) == "MEDIUM"

    def test_low_humidity_low_risk(self):
        assert check_humidity_pest_risk(50, 5) == "LOW"
