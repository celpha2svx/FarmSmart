"""
Africa's Talking SMS gateway handler.
Used as primary or fallback channel for farmers.
Cost: ~₦4–₦8 per SMS.
"""

import os
import logging
import re
from utils.http_client import build_client
from utils.config import settings

logger = logging.getLogger(__name__)

AT_USERNAME  = settings.at_username
AT_API_KEY   = settings.at_api_key
AT_BASE_URL  = "https://api.africastalking.com/version1/messaging"
AT_SENDER_ID = "FarmSmart"


def send_sms(phone: str, message: str) -> bool:
    """Send an SMS via Africa's Talking gateway.

    Args:
        phone:   Recipient phone (e.g. 2348012345678)
        message: SMS text

    Returns:
        True if sent successfully.
    """
    if not AT_API_KEY:
        logger.warning("AT_API_KEY not set. SMS not sent.")
        return False

    message = message[:320]

    try:
        client = build_client(timeout=15)
        headers = {
            "apiKey":       AT_API_KEY,
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept":       "application/json",
        }
        payload = {
            "username": AT_USERNAME,
            "to":       phone,
            "message":  message,
            "from":     AT_SENDER_ID,
        }
        response = client.post(AT_BASE_URL, data=payload, headers=headers)
        response.raise_for_status()
        result = response.json()
        recipients = result.get("SMSMessageData", {}).get("Recipients", [])
        if recipients and recipients[0].get("status") == "Success":
            logger.info(f"SMS sent to {phone}: {recipients[0].get('cost', 'N/A')}")
            return True
        logger.warning(f"SMS to {phone} responded: {result}")
        return False
    except Exception as e:
        logger.error(f"SMS send failed for {phone}: {e}")
        return False


def sms_format(message: str) -> str:
    """Strip WhatsApp markdown and emoji for plain SMS delivery."""
    text = re.sub(r"\*(.+?)\*", r"\1", message)
    text = re.sub(r"_(.+?)_", r"\1", text)
    text = re.sub(r"[🌱🔴🟡🟢📉📈💧⚠️✅⛅🌧🌦☀️🚜🛡🔍⏸✏️🚶⚪🇳🇬✅🟢⚪🔴🟡🌱🌴🥔🥬🫘🌾]", "", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()