"""
Farmer registration flow — 3-question WhatsApp onboarding.

State machine stored in memory (redis or DB would be used in production).
Under 2 minutes, WhatsApp-native numbered choices with category grouping.
"""

import logging
from utils.geocoding import resolve_location
from utils.helpers import generate_uuid
from utils.constants import ALL_CROPS, CROP_CATEGORIES

logger = logging.getLogger(__name__)

# In-memory state store for multi-step registration
# Format: { phone: { 'step': int, 'data': dict } }
_REGISTRATION_STATE: dict[str, dict] = {}

FARM_SIZES = {
    "1": "small",
    "2": "medium",
    "3": "large",
}


def _build_crop_menu() -> str:
    """Build a categorised crop selection menu."""
    lines = []
    idx = 0
    CATEGORY_LABELS = {
        "grains":       "🌾 Grains",
        "legumes":      "🫘 Legumes",
        "tubers_roots": "🥔 Tubers & Roots",
        "vegetables":   "🥬 Vegetables",
        "cash_tree":    "🌴 Cash & Tree Crops",
    }
    for cat_key, crops in CROP_CATEGORIES.items():
        lines.append(f"\n{CATEGORY_LABELS.get(cat_key, cat_key)}:")
        for crop in crops:
            idx += 1
            display = crop.replace("_", " ").title()
            lines.append(f"{idx}. {display}")
    return "\n".join(lines)


WELCOME_MESSAGE = (
    "🌱 *Welcome to FarmSmart!*\n\n"
    "I'll help you get precise weather, soil, and pest advice for your farm.\n\n"
    "Let's set you up in under 2 minutes.\n\n"
    "*Question 1 of 3:*\n"
    "What crop do you grow?"
    + _build_crop_menu()
    + "\n\n_Reply with a number (e.g. 1 for Maize)_"
)

LOCATION_PROMPT = (
    "*Question 2 of 3:*\n"
    "Where is your farm?\n\n"
    "Reply with your LGA or nearest town.\n"
    "_Example: Sabon Gari · Zaria · Ibadan North_"
)

SIZE_PROMPT = (
    "*Question 3 of 3:*\n"
    "How big is your farm?\n\n"
    "1. Less than 1 hectare\n"
    "2. 1–5 hectares\n"
    "3. More than 5 hectares\n\n"
    "_Reply with 1, 2, or 3_"
)


def is_registering(phone: str) -> bool:
    return phone in _REGISTRATION_STATE


def start_registration(phone: str) -> str:
    _REGISTRATION_STATE[phone] = {"step": 1, "data": {}}
    return WELCOME_MESSAGE


def handle_registration_step(phone: str, text: str) -> tuple[str, dict | None]:
    """
    Process one step of the registration flow.

    Returns:
        (message_to_send, farmer_data_dict_or_None)
        farmer_data_dict is returned only when registration is complete.
    """
    state = _REGISTRATION_STATE.get(phone)
    if not state:
        return start_registration(phone), None

    step = state["step"]
    data = state["data"]

    # ── Step 1: Crop selection ─────────────────────────────────────────────
    if step == 1:
        try:
            idx = int(text.strip()) - 1
            if 0 <= idx < len(ALL_CROPS):
                crop = ALL_CROPS[idx]
                data["crop"] = crop
                state["step"] = 2
                return LOCATION_PROMPT, None
        except (ValueError, IndexError):
            pass
        return f"Please reply with a number 1–{len(ALL_CROPS)} for your crop.", None

    # ── Step 2: Location ───────────────────────────────────────────────────
    if step == 2:
        location_raw = text.strip().title()
        coords = resolve_location(location_raw)
        if coords:
            data["location_raw"] = location_raw
            data["lat"], data["lon"] = coords
            state["step"] = 3
            return SIZE_PROMPT, None
        return (
            f"I couldn't find *{location_raw}* in my database.\n\n"
            "Please try your LGA name or nearest major town.\n"
            "_Example: Zaria · Ibadan North · Abeokuta_"
        ), None

    # ── Step 3: Farm size ──────────────────────────────────────────────────
    if step == 3:
        size_key = text.strip()
        farm_size = FARM_SIZES.get(size_key)
        if farm_size:
            data["farm_size"] = farm_size
            data["phone"]     = phone
            _REGISTRATION_STATE.pop(phone, None)

            crop     = data["crop"].replace("_", " ").title()
            location = data["location_raw"]
            confirm  = (
                f"✅ *You're registered!*\n\n"
                f"Crop: {crop}\n"
                f"Farm: {location}\n"
                f"Size: {size_key} ({'< 1ha' if size_key == '1' else '1–5ha' if size_key == '2' else '> 5ha'})\n\n"
                f"*Available commands:*\n"
                f"SOIL — Soil moisture status\n"
                f"WEATHER — 3-day forecast\n"
                f"PEST — Pest risk for your crop\n"
                f"DAILY — Subscribe to 6AM daily updates\n"
                f"HELP — Full command list\n\n"
                f"Your first update arrives tomorrow morning at 6 AM.\n"
                f"_Reply SOIL or WEATHER to get your first report now!_"
            )
            return confirm, data
        return "Please reply with 1, 2, or 3 for your farm size.", None

    return "Something went wrong. Send REGISTER to start again.", None