"""
WhatsApp Cloud API integration — Meta Graph API v18.0.
Handles sending messages and webhook signature verification.
"""

import os
import hmac
import hashlib
import logging
import json
from utils.http_client import build_client

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
        client = build_client(timeout=15)
        response = client.post(url, headers=headers, json=data)
        response.raise_for_status()
        msg_id = response.json().get("messages", [{}])[0].get("id", "?")
        logger.info(f"WhatsApp message sent to {to}: id={msg_id}")
        return True
    except Exception as e:
        logger.error(f"WhatsApp send failed for {to}: {e}")
    return False


def verify_webhook_signature(body: bytes, signature_header: str | None) -> bool:
    """
    Verify that a webhook request came from Meta using HMAC-SHA256.

    Meta signs every POST to /webhook with X-Hub-Signature-256.
    The signature is HMAC-SHA256 of the raw request body using WHATSAPP_TOKEN as key.

    Args:
        body:             Raw request body bytes
        signature_header: The X-Hub-Signature-256 header value (e.g. "sha256=abc123...")

    Returns:
        True if signature is valid or no signature check required (dev mode).
    """
    if not signature_header:
        logger.warning("Webhook missing X-Hub-Signature-256 — rejecting")
        return False

    if not WHATSAPP_TOKEN:
        logger.warning("WHATSAPP_TOKEN not set — cannot verify webhook signature")
        return False

    expected_prefix = "sha256="
    if not signature_header.startswith(expected_prefix):
        logger.warning(f"Invalid signature header format")
        return False

    received_sig = signature_header[len(expected_prefix):]
    expected_sig = hmac.new(
        WHATSAPP_TOKEN.encode(),
        body,
        hashlib.sha256,
    ).hexdigest()

    if not hmac.compare_digest(received_sig, expected_sig):
        logger.warning("Webhook signature mismatch — possible forgery")
        return False

    return True


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