"""
Africa's Talking SMS gateway handler.
Used as fallback for feature-phone farmers who cannot use WhatsApp.
Cost: ~₦4–₦8 per SMS.
"""

import os
import logging
import httpx

logger = logging.getLogger(__name__)

AT_API_KEY   = os.environ.get("AT_API_KEY", "")
AT_USERNAME  = os.environ.get("AT_USERNAME", "sandbox")
AT_BASE_URL  = "https://api.africastalking.com/version1/messaging"
AT_SENDER_ID = "FarmSmart"


def send_sms(phone: str, message: str) -> bool:
    """
    Send an SMS via Africa's Talking gateway.

    Args:
        phone:   Recipient phone number in international format (+234...)
        message: SMS text (max 160 chars per segment)

    Returns:
        True if sent successfully, False otherwise.
    """
    if not AT_API_KEY:
        logger.warning("Africa's Talking API key not configured. SMS not sent.")
        return False

    # Truncate to 320 chars (2 SMS segments) for cost control
    message = message[:320]

    try:
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
        response = httpx.post(
            AT_BASE_URL, data=payload, headers=headers, timeout=15
        )
        response.raise_for_status()
        result = response.json()
        sms_data = result.get("SMSMessageData", {})
        recipients = sms_data.get("Recipients", [])

        if recipients and recipients[0].get("status") == "Success":
            logger.info(f"SMS sent to {phone}: {recipients[0].get('cost', 'N/A')}")
            return True
        logger.warning(f"SMS to {phone} returned unexpected response: {result}")
        return False

    except Exception as e:
        logger.error(f"SMS send failed for {phone}: {e}")
        return False


def sms_format(message: str) -> str:
    """
    Strip WhatsApp markdown formatting for plain SMS delivery.
    Removes *bold*, _italic_, emoji for cleaner SMS text.
    """
    import re
    text = re.sub(r"\*(.+?)\*", r"\1", message)   # Remove *bold*
    text = re.sub(r"_(.+?)_",   r"\1", text)       # Remove _italic_
    text = re.sub(r"🌱|🔴|🟡|🟢|📉|📈|💧|⚠️|✅|⛅|🌧|🌦|☀️|🚜|🛡|🔍|⏸|✏️|🚶|⚪|🇳🇬", "", text)
    text = re.sub(r"\n{3,}", "\n\n", text)         # Collapse extra newlines
    return text.strip()
