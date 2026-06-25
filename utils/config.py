"""
FarmSmart configuration — loaded from environment with Pydantic Settings.
Replaces scattered os.environ.get() calls across the codebase.
"""

import os
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # WhatsApp
    whatsapp_token: str = ""
    phone_number_id: str = ""
    verify_token: str = "farmsmart_verify"

    # Database
    database_url: str = "sqlite:///./farmsmart.db"

    # Africa's Talking (SMS fallback)
    at_api_key: str = ""
    at_username: str = "sandbox"

    # NASA EarthData
    earthdata_token: str = ""

    # App
    app_env: str = "development"
    log_level: str = "INFO"

    # Slack alerts (optional)
    slack_webhook_url: str = ""

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()