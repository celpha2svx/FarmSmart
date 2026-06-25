"""
Simple in-memory rate limiter — per phone number.
Tracks message count per sliding window.
"""

import time
import logging
from collections import defaultdict

logger = logging.getLogger(__name__)

# Config
MAX_MESSAGES_PER_WINDOW = 10
WINDOW_SECONDS = 60

# { phone: [(timestamp, count), ...] }
_rate_store: dict[str, list[float]] = defaultdict(list)


def is_rate_limited(phone: str) -> bool:
    """
    Check if a phone has exceeded the rate limit.

    Returns True if the phone should be blocked (too many requests).
    """
    now = time.time()
    cutoff = now - WINDOW_SECONDS

    # Prune old entries
    timestamps = _rate_store[phone]
    _rate_store[phone] = [t for t in timestamps if t > cutoff]

    current_count = len(_rate_store[phone])

    if current_count >= MAX_MESSAGES_PER_WINDOW:
        logger.warning(f"Rate limit exceeded for {phone} ({current_count} msgs in {WINDOW_SECONDS}s)")
        return True

    _rate_store[phone].append(now)
    return False


def get_remaining(phone: str) -> int:
    """Return how many messages the phone can still send in this window."""
    now = time.time()
    cutoff = now - WINDOW_SECONDS
    timestamps = [t for t in _rate_store.get(phone, []) if t > cutoff]
    return max(0, MAX_MESSAGES_PER_WINDOW - len(timestamps))