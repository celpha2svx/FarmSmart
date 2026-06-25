"""
WhatsApp Cloud API integration — Meta Graph API v18.0.
Handles sending messages and the webhook verification handshake.
"""

import os
import logging
import requests

logger = logging.getLogger(__name__)

WHATSAPP_TOKEN  = os.environ.get("WHATSAPP_TOKEN", "")
PHONE_NUMBER_ID = os.environ.get("PHONE_NUMBER_ID", "")
WA_API_VERSION  = "v18.0"


def send_whatsapp_message(to: str, body: str) -> bool:
    """
    Send a WhatsApp text message via Meta Cloud API.

    Args:
        to:   Recipient phone number in international format (e.g. 2348012345678)
        body: Message body text (WhatsApp markdown supported)

    Returns:
        True if sent successfully, False otherwise.
    """
    if not WHATSAPP_TOKEN or not PHONE_NUMBER_ID:
        logger.error("WhatsApp credentials not configured. Check .env file.")
        return False

    url  = f"https://graph.facebook.com/{WA_API_VERSION}/{PHONE_NUMBER_ID}/messages"
    data = {
        "messaging_product": "whatsapp",
        "to":                to,
        "type":              "text",
        "text":              {"body": body, "preview_url": False},
    }
    headers = {
        "Authorization": f"Bearer {WHATSAPP_TOKEN}",
        "Content-Type":  "application/json",
    }

    try:
        response = requests.post(url, headers=headers, json=data, timeout=15)
        response.raise_for_status()
        msg_id = response.json().get("messages", [{}])[0].get("id", "?")
        logger.info(f"WhatsApp message sent to {to}: id={msg_id}")
        return True
    except requests.HTTPError as e:
        logger.error(f"WhatsApp API HTTP error for {to}: {e.response.text}")
    except Exception as e:
        logger.error(f"WhatsApp send failed for {to}: {e}")
    return False


def extract_message(webhook_body: dict) -> dict | None:
    """
    Extract phone number and message text from a WhatsApp webhook payload.

    Returns:
        {'phone': str, 'text': str} or None if no message found.
    """
    try:
        entry   = webhook_body.get("entry", [{}])[0]
        changes = entry.get("changes", [{}])[0]
        value   = changes.get("value", {})
        messages = value.get("messages", [])
        if not messages:
            return None
        msg   = messages[0]
        phone = msg["from"]
        text  = msg.get("text", {}).get("body", "").strip()
        return {"phone": phone, "text": text}
    except (IndexError, KeyError, TypeError) as e:
        logger.warning(f"Could not parse webhook body: {e}")
        return None
