"""
Tests for configuration, rate limiter, and admin alerts.
"""

import pytest
from utils.config import Settings


class TestConfig:
    def test_default_values(self):
        """Settings should have sensible defaults without .env file."""
        s = Settings()
        assert s.database_url == "sqlite:///./farmsmart.db"
        assert s.app_env == "development"
        assert s.log_level == "INFO"
        assert s.slack_webhook_url == ""

    def test_env_override(self, monkeypatch):
        monkeypatch.setenv("DATABASE_URL", "postgresql://localhost:5432/test")
        monkeypatch.setenv("APP_ENV", "production")
        s = Settings()
        assert s.database_url == "postgresql://localhost:5432/test"
        assert s.app_env == "production"


class TestRateLimiter:
    def test_first_request_not_limited(self):
        from utils.rate_limiter import is_rate_limited, _rate_store
        _rate_store.clear()
        assert not is_rate_limited("+2348000000001")

    def test_many_requests_eventually_limited(self):
        from utils.rate_limiter import is_rate_limited, _rate_store, MAX_MESSAGES_PER_WINDOW
        _rate_store.clear()
        phone = "+2348000000002"
        # Send MAX_MESSAGES_PER_WINDOW requests
        for _ in range(MAX_MESSAGES_PER_WINDOW):
            is_rate_limited(phone)
        # The next one should be limited
        assert is_rate_limited(phone)

    def test_different_phones_independent(self):
        from utils.rate_limiter import is_rate_limited, _rate_store, MAX_MESSAGES_PER_WINDOW
        _rate_store.clear()
        # Exhaust phone A
        for _ in range(MAX_MESSAGES_PER_WINDOW):
            is_rate_limited("+2348000000100")
        assert is_rate_limited("+2348000000100")
        # Phone B should be fine
        assert not is_rate_limited("+2348000000101")


class TestAdminAlerts:
    def test_no_slack_no_error(self):
        """notify_admin should log warning but not crash when no Slack URL."""
        from utils.admin_alerts import notify_admin
        # Should not raise
        notify_admin("Test message")