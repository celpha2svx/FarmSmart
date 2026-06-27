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

    # Telegram bot (optional — alternative to WhatsApp)
    telegram_token: str = ""

    # Slack alerts (optional)
    slack_webhook_url: str = ""

    # Cloudflare Worker webhook for feedback → GitHub Issues
    feedback_webhook_url: str = ""

    # Admin token for CI/CD to register releases
    admin_token: str = ""

    # HuggingFace Inference API token (free tier)
    huggingface_token: str = ""
    huggingface_model: str = "pierreguillou/nlp-v2.0-classifier-plant-disease"

    # AFEX API
    afex_api_base: str = "https://api-md.afexnigeria.com/AFEXMD/api/v1"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8", "env_ignore_case": True}


settings = Settings()