"""
Shared utility functions used across FarmSmart modules.
"""

import uuid
import logging
from datetime import datetime, timezone


logger = logging.getLogger(__name__)


def generate_uuid() -> str:
    """Generate a new UUID string."""
    return str(uuid.uuid4())


def utcnow_iso() -> str:
    """Return current UTC time as an ISO 8601 string."""
    return datetime.now(timezone.utc).isoformat()


def normalize_command(text: str) -> str:
    """Strip and uppercase a command string received from WhatsApp."""
    return text.strip().upper()


def safe_float(value, default: float = 0.0) -> float:
    """Safely cast a value to float, returning default on failure."""
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def crop_display_name(crop: str) -> str:
    """Return a human-readable crop name."""
    return crop.strip().title()


def format_risk_emoji(risk_level: str) -> str:
    """Map risk level string to an emoji indicator."""
    return {
        "HIGH":    "🔴",
        "MEDIUM":  "🟡",
        "LOW":     "🟢",
        "MINIMAL": "⚪",
    }.get(risk_level.upper(), "⚪")


def clamp(value: float, min_val: float, max_val: float) -> float:
    """Clamp a float between min and max."""
    return max(min_val, min(max_val, value))
