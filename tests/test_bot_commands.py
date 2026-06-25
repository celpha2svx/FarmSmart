"""
Tests for bot command routing — verifies each command returns a valid string.
Uses mock Farmer objects so no real DB or API calls are made.
"""

import pytest
from unittest.mock import patch, MagicMock


def make_farmer(crop="maize", location="Sabon Gari, Kaduna", lat=11.1, lon=7.7):
    """Create a mock Farmer object for testing."""
    farmer = MagicMock()
    farmer.phone        = "+2348012345678"
    farmer.crop         = crop
    farmer.location_raw = location
    farmer.lat          = lat
    farmer.lon          = lon
    farmer.farm_size    = "medium"
    farmer.subscribed   = 1
    farmer.daily_update = 1
    return farmer


# ── Command handler tests (all commands mocked to avoid API calls) ─────────────

class TestCommandHandlers:

    def test_help_message_returns_all_commands(self):
        from bot.commands import get_help_message
        msg = get_help_message(make_farmer())
        for cmd in ("SOIL", "WEATHER", "PEST", "DAILY", "STOP", "HELP"):
            assert cmd in msg

    def test_unknown_command_returns_hint(self):
        from bot.commands import get_unknown_command
        msg = get_unknown_command(make_farmer())
        assert "HELP" in msg

    def test_stop_command_message(self):
        from bot.commands import handle_stop
        msg = handle_stop(make_farmer())
        assert "paused" in msg.lower()

    def test_update_command_message(self):
        from bot.commands import handle_update
        msg = handle_update(make_farmer())
        assert "UPDATE" in msg

    def test_daily_subscribe_message(self):
        from bot.commands import subscribe_daily
        msg = subscribe_daily(make_farmer())
        assert "6 AM" in msg or "activated" in msg.lower()

    def test_pest_signs_maize_returns_faw_signs(self):
        from bot.commands import get_pest_signs
        msg = get_pest_signs(make_farmer(crop="maize"))
        assert isinstance(msg, str)
        assert len(msg) > 50

    def test_scouting_guide_returns_steps(self):
        from bot.commands import get_scouting_guide_message
        msg = get_scouting_guide_message(make_farmer())
        assert "1." in msg

    @patch("bot.commands.fetch_weather_forecast")
    def test_weather_command_returns_forecast(self, mock_weather):
        from bot.commands import get_weather_message
        mock_weather.return_value = {
            "daily": [
                {"date": "2026-06-24", "temperature_c": 30, "temp_max": 34,
                 "temp_min": 24, "rainfall_mm": 0, "rain_probability": 10,
                 "humidity_percent": 45, "wind_speed_ms": 2, "solar_radiation_mj": 18},
            ],
            "location": {"lat": 11.1, "lon": 7.7},
        }
        msg = get_weather_message(make_farmer())
        assert isinstance(msg, str)
        assert len(msg) > 30

    @patch("bot.commands.fetch_soil_moisture")
    @patch("bot.commands.fetch_weather_forecast")
    @patch("bot.commands.get_elevation")
    def test_soil_command_returns_message(self, mock_elev, mock_weather, mock_soil):
        from bot.commands import get_soil_moisture_message
        mock_soil.return_value  = {"sm_value": 0.22, "source": "open-meteo", "quality": "high"}
        mock_elev.return_value  = 612.0
        mock_weather.return_value = {
            "daily": [
                {"temperature_c": 30, "temp_max": 34, "temp_min": 24,
                 "humidity_percent": 50, "rainfall_mm": 0,
                 "wind_speed_ms": 2, "solar_radiation_mj": 18},
            ] * 5,
            "location": {"lat": 11.1, "lon": 7.7},
        }
        msg = get_soil_moisture_message(make_farmer())
        assert "Soil" in msg or "soil" in msg

    @patch("bot.commands.fetch_weather_forecast")
    def test_pest_command_no_risk_returns_clear(self, mock_weather):
        from bot.commands import get_pest_message
        mock_weather.return_value = {
            "daily": [
                {"temp_max": 28, "temp_min": 18, "humidity_percent": 40},
            ] * 7,
            "location": {"lat": 11.1, "lon": 7.7},
        }
        msg = get_pest_message(make_farmer())
        assert isinstance(msg, str)
        assert len(msg) > 10


# ── Registration flow tests ────────────────────────────────────────────────────

class TestRegistrationFlow:

    def test_start_registration_returns_welcome(self):
        from bot.registration import start_registration
        msg = start_registration("+2348000000001")
        assert "Welcome" in msg
        assert "Maize" in msg

    def test_valid_crop_selection_advances(self):
        from bot.registration import start_registration, handle_registration_step
        phone = "+2348000000002"
        start_registration(phone)
        msg, data = handle_registration_step(phone, "1")  # Maize
        assert data is None
        assert "farm" in msg.lower() or "location" in msg.lower() or "Question 2" in msg

    def test_invalid_crop_selection_prompts_retry(self):
        from bot.registration import start_registration, handle_registration_step
        from utils.constants import ALL_CROPS
        phone = "+2348000000003"
        start_registration(phone)
        msg, data = handle_registration_step(phone, "99")
        assert data is None
        assert "1" in msg and str(len(ALL_CROPS)) in msg

    def test_full_registration_flow(self):
        from bot.registration import start_registration, handle_registration_step, is_registering
        phone = "+2348000000099"
        start_registration(phone)

        # Step 1: crop
        handle_registration_step(phone, "1")  # Maize
        # Step 2: location
        handle_registration_step(phone, "Zaria")
        # Step 3: farm size
        msg, data = handle_registration_step(phone, "2")  # 1–5 ha

        assert data is not None
        assert data["crop"] == "maize"
        assert data["farm_size"] == "medium"
        assert not is_registering(phone)  # State cleared after completion
