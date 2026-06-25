"""
Pre-configured HTTP client with retry logic and timeouts.
All external API calls go through this module.
"""

import httpx
import logging

logger = logging.getLogger(__name__)

DEFAULT_TIMEOUT = 30.0
MAX_RETRIES = 3


def build_client(
    timeout: float = DEFAULT_TIMEOUT,
    max_retries: int = MAX_RETRIES,
) -> httpx.Client:
    """Create an httpx Client with retry and timeout configured."""
    transport = httpx.HTTPTransport(
        retries=max_retries,
    )
    return httpx.Client(
        transport=transport,
        timeout=httpx.Timeout(timeout),
        follow_redirects=True,
    )


def build_async_client(
    timeout: float = DEFAULT_TIMEOUT,
    max_retries: int = MAX_RETRIES,
) -> httpx.AsyncClient:
    """Create an async httpx Client with retry and timeout configured."""
    transport = httpx.AsyncHTTPTransport(
        retries=max_retries,
    )
    return httpx.AsyncClient(
        transport=transport,
        timeout=httpx.Timeout(timeout),
        follow_redirects=True,
    )