"""
Admin alert channels — Slack, etc.
Used to notify the team when critical errors occur in production.
"""

import logging
from utils.http_client import build_client
from utils.config import settings

logger = logging.getLogger(__name__)


def notify_admin(message: str) -> None:
    """
    Send an alert to the admin team via configured channels.
    Currently only Slack webhook is supported.
    """
    if settings.slack_webhook_url:
        _send_slack(message)
    else:
        logger.warning(f"Admin alert (no Slack configured): {message}")


def _send_slack(message: str) -> None:
    """Send a message to Slack via webhook."""
    try:
        client = build_client(timeout=10)
        resp = client.post(
            settings.slack_webhook_url,
            json={"text": f"[FarmSmart] {message}"},
        )
        resp.raise_for_status()
        logger.info("Slack admin alert sent")
    except Exception as e:
        logger.error(f"Failed to send Slack alert: {e}")