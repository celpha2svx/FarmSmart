"""
Tests for the data → plain language translation layer.
Verifies that correct status labels and actions are generated.
"""

import pytest
from translation.soil_to_message import translate_soil_moisture
from translation.pest_to_message import (
    translate_pest_risk, get_pest_signs_message, get_scouting_guide
)
from translation.weather_to_message import translate_weather_forecast


# ── Soil moisture translation ──────────────────────────────────────────────────

class TestSoilTranslation:
    def test_critically_low_maize(self):
        msg = translate_soil_moisture(sm_value=0.12, sm_trend=-0.03, crop="maize")
        assert "CRITICALLY LOW" in msg
        assert "IMMEDIATELY" in msg

    def test_low_maize(self):
        msg = translate_soil_moisture(sm_value=0.17, sm_trend=-0.01, crop="maize")
        assert "LOW" in msg
        assert "24 hours" in msg

    def test_adequate_maize(self):
        msg = translate_soil_moisture(sm_value=0.25, sm_trend=0.01, crop="maize")
        assert "ADEQUATE" in msg
        assert "No irrigation" in msg

    def test_cassava_different_threshold(self):
        # Cassava critical=0.10 — 0.12 is LOW not critical
        msg = translate_soil_moisture(sm_value=0.12, sm_trend=0.0, crop="cassava")
        assert "LOW" in msg or "ADEQUATE" in msg

    def test_dropping_fast_trend(self):
        msg = translate_soil_moisture(sm_value=0.25, sm_trend=-0.03, crop="maize")
        assert "Dropping fast" in msg

    def test_improving_trend(self):
        msg = translate_soil_moisture(sm_value=0.25, sm_trend=0.02, crop="maize")
        assert "Improving" in msg

    def test_unknown_crop_defaults_to_maize(self):
        """Unknown crops should fall back to maize thresholds."""
        msg = translate_soil_moisture(sm_value=0.12, sm_trend=0.0, crop="unknown_crop")
        assert "CRITICALLY LOW" in msg


# ── Pest translation ───────────────────────────────────────────────────────────

class TestPestTranslation:
    def high_risk_data(self):
        return {
            "pest":             "Fall Armyworm",
            "daily_dd":         15.5,
            "accumulated_dd":   290.0,
            "threshold":        350.0,
            "progress_percent": 82.9,
            "generations":      0,
            "risk_level":       "HIGH",
        }

    def medium_risk_data(self):
        return {**self.high_risk_data(), "progress_percent": 65.0, "risk_level": "MEDIUM"}

    def minimal_risk_data(self):
        return {**self.high_risk_data(), "progress_percent": 20.0, "risk_level": "MINIMAL"}

    def test_high_risk_returns_alert(self):
        msg = translate_pest_risk(self.high_risk_data())
        assert msg is not None
        assert "PEST ALERT" in msg
        assert "HIGH" in msg

    def test_medium_risk_returns_advisory(self):
        msg = translate_pest_risk(self.medium_risk_data())
        assert msg is not None
        assert "Advisory" in msg or "MODERATE" in msg

    def test_minimal_risk_returns_none(self):
        msg = translate_pest_risk(self.minimal_risk_data())
        assert msg is None

    def test_humidity_high_overrides_low_dd(self):
        msg = translate_pest_risk(self.minimal_risk_data(), humidity_risk="HIGH")
        assert msg is not None
        assert "HIGH" in msg

    def test_pest_signs_fall_armyworm(self):
        msg = get_pest_signs_message("Fall Armyworm")
        assert "frass" in msg.lower() or "holes" in msg.lower()

    def test_scouting_guide_contains_steps(self):
        msg = get_scouting_guide("maize")
        assert "1." in msg
        assert "morning" in msg.lower()


# ── Weather translation ────────────────────────────────────────────────────────

class TestWeatherTranslation:
    def sample_forecast(self):
        return [
            {"date": "2026-06-24", "temperature_c": 30, "temp_max": 34, "temp_min": 24,
             "rainfall_mm": 0, "rain_probability": 10, "humidity_percent": 45},
            {"date": "2026-06-25", "temperature_c": 27, "temp_max": 30, "temp_min": 22,
             "rainfall_mm": 12, "rain_probability": 75, "humidity_percent": 80},
            {"date": "2026-06-26", "temperature_c": 29, "temp_max": 32, "temp_min": 23,
             "rainfall_mm": 2, "rain_probability": 30, "humidity_percent": 60},
        ]

    def test_message_contains_3_days(self):
        msg = translate_weather_forecast(self.sample_forecast())
        assert "Today" in msg
        assert "Tomorrow" in msg
        assert "Day 3" in msg

    def test_rain_tomorrow_delays_fertilizer(self):
        msg = translate_weather_forecast(self.sample_forecast())
        assert "fertilizer" in msg.lower() or "spray" in msg.lower()

    def test_empty_forecast_returns_warning(self):
        msg = translate_weather_forecast([])
        assert "unavailable" in msg.lower()
