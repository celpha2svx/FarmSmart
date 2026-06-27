"""
FarmSmart Advisory Rules Engine.

Generates real agronomic advisories based on crop, growth stage, region,
season, and satellite data. Uses only rules — no ML dependency.

Supported crops: maize, rice, cassava, yam, beans, millet, sorghum, groundnut,
cocoa, tomato, onion, okra, garden_egg, pepper, water_melon, sweet_potato,
cowpea, soya_beans, ginger, sesame.
"""

from datetime import datetime, date
from typing import Optional


# ── Growth stage calculator ──────────────────────────────────────────────────

def get_growth_stage(crop: str, days_since_planting: int) -> str:
    """Return growth stage name and percentage complete."""
    stages = _CROP_STAGES.get(crop, {"duration": 120, "stages": []})
    total_days = stages["duration"]
    pct = min(100, int((days_since_planting / total_days) * 100))

    for stage in stages["stages"]:
        if stage["start"] <= days_since_planting <= stage["end"]:
            return {
                "stage": stage["name"],
                "pct": pct,
                "days_remaining": max(0, total_days - days_since_planting),
                "stage_label": stage["label"],
            }
    if days_since_planting < 0:
        return {"stage": "pre_planting", "pct": 0, "days_remaining": total_days, "stage_label": "Pre-planting"}
    return {"stage": "mature", "pct": 100, "days_remaining": 0, "stage_label": "Mature / Ready for harvest"}


def get_season(lat: float) -> str:
    """Determine wet/dry season based on latitude (Nigeria)."""
    if lat >= 10.0:  # Northern Nigeria
        return "dry" if datetime.now().month in [11, 12, 1, 2, 3, 4] else "wet"
    elif lat >= 7.5:  # Middle belt
        return "dry" if datetime.now().month in [12, 1, 2] else "wet"
    else:  # Southern Nigeria
        return "dry" if datetime.now().month in [1, 2] else "wet"


def get_region(lat: float) -> str:
    if lat >= 9.0:
        return "north"
    elif lat <= 7.0:
        return "south"
    return "middle_belt"


# ── Advisory generators ──────────────────────────────────────────────────────

def generate_daily_advisory(
    crop: str,
    days_since_planting: int,
    lat: float,
    lon: float,
    ndvi: Optional[float] = None,
    evapotranspiration: Optional[float] = None,
    soil_moisture: Optional[float] = None,
) -> dict:
    """Generate a structured daily advisory for the home dashboard."""
    season = get_season(lat)
    region = get_region(lat)
    growth = get_growth_stage(crop, days_since_planting)
    stage = growth["stage"]

    crop_info = _CROP_INFO.get(crop, {})
    crop_name = crop_info.get("name", crop.replace("_", " ").title())
    emoji = crop_info.get("emoji", "🌱")
    pests = crop_info.get("common_pests", [])

    advisory = {
        "crop": crop,
        "crop_name": crop_name,
        "emoji": emoji,
        "season": season,
        "region": region,
        "growth_stage": growth,
        "title": f"{emoji} {crop_name} Advisory — {growth['stage_label']}",
        "message": "",
        "risk_level": "low",
        "tips": [],
        "warnings": [],
        "action_items": [],
    }

    # ── Stage-specific advisories ──
    if stage in ("pre_planting",):
        advisory["message"] = _pre_planting_advice(crop, season, region)
    elif stage in ("germination", "seedling", "establishment", "sprouting", "nursery"):
        advisory["message"], tips, warnings = _early_stage_advice(crop, season, days_since_planting)
        advisory["tips"].extend(tips)
        advisory["warnings"].extend(warnings)
    elif stage in ("vegetative", "vegetative_growth", "tillering", "vine_growth"):
        advisory["message"], tips, warnings = _vegetative_advice(crop, season, days_since_planting, pests)
        advisory["tips"].extend(tips)
        advisory["warnings"].extend(warnings)
    elif stage in ("flowering", "fruiting", "grain_fill", "pod_development", "tuber_bulking",
                   "tasseling", "silking", "panicle", "pod_fill", "rhizome_bulking",
                   "bulb_formation", "capsule_set"):
        advisory["message"], tips, warnings = _reproductive_advice(crop, season, days_since_planting, pests)
        advisory["tips"].extend(tips)
        advisory["warnings"].extend(warnings)
    elif stage in ("maturation", "ripening", "maturity", "pod_maturity", "fruit_maturation",
                   "capsule_maturation", "harvest"):
        advisory["message"], tips, warnings = _maturation_advice(crop, season, days_since_planting)
        advisory["tips"].extend(tips)
        advisory["warnings"].extend(warnings)
    elif stage == "mature":
        advisory["message"], tips, warnings = _harvest_advice(crop, season)
        advisory["tips"].extend(tips)
        advisory["warnings"].extend(warnings)
    else:
        advisory["message"] = f"Monitor your {crop_name} field regularly. Keep the area weed-free."

    # ── Satellite data overlay ──
    if ndvi is not None:
        if ndvi < 0.2:
            advisory["warnings"].append("Low vegetation index detected. Check for crop stress or poor growth.")
            if advisory["risk_level"] == "low":
                advisory["risk_level"] = "medium"
        elif ndvi > 0.7:
            advisory["tips"].append("Healthy vegetation cover detected. Continue current management.")

    if soil_moisture is not None:
        if soil_moisture < 0.15:
            advisory["warnings"].append("Low soil moisture. Consider irrigation if in dry season.")
            if advisory["risk_level"] == "low":
                advisory["risk_level"] = "medium"
        elif soil_moisture > 0.45:
            advisory["warnings"].append("High soil moisture. Watch for waterlogging and root rot.")

    if evapotranspiration is not None and evapotranspiration > 5.0:
        advisory["tips"].append("High evaporation rate. Consider mulching to conserve soil moisture.")

    # ── Season-specific warnings ──
    if season == "dry" and region == "north":
        advisory["warnings"].append("Dry season — plan irrigation scheduling carefully.")
    if season == "wet" and region == "south":
        advisory["warnings"].append("Heavy rains expected. Ensure drainage channels are clear.")

    # ── Derive action items ──
    advisory["action_items"] = _derive_actions(advisory["tips"], advisory["warnings"])

    return advisory


# ── Stage advice generators ─────────────────────────────────────────────────

def _pre_planting_advice(crop: str, season: str, region: str) -> str:
    advice = {
        "maize": f"Prepare land for maize planting. Plough and harrow to fine tilth. {'Wait for rains to establish' if season == 'dry' else 'Plant as soon as land is ready.'}",
        "rice": f"Prepare nursery beds for rice. Soak seeds for 24 hours and incubate for 48 hours before sowing. {'Dry-season rice requires irrigation' if season == 'dry' else 'Prepare to transplant after 3 weeks in nursery.'}",
        "cassava": f"Select healthy cassava stems from disease-free plants. Cut into 25cm lengths with 5-7 nodes.",
        "yam": f"Prepare yam mounds or ridges 1m apart. Select healthy seed yams of 200-500g. Treat with fungicide before planting.",
        "beans": f"Prepare seedbed for beans. Inoculate seeds with rhizobium bacteria for better nitrogen fixation.",
        "tomato": f"Prepare nursery beds for tomato. Sow seeds in well-drained soil. Transplant after 4-5 weeks.",
        "onion": f"Prepare nursery for onion. Sow seeds thinly and water regularly. Transplant after 8 weeks.",
    }
    return advice.get(crop, f"Prepare land for {crop.replace('_', ' ')}. Clear weeds and apply well-decomposed organic manure.")


def _early_stage_advice(crop: str, season: str, dap: int):
    tips = []
    warnings = []

    # General early-stage tips
    tips.append("Keep the field weed-free. Early weeds compete strongly with young crops.")
    tips.append("Monitor soil moisture — young plants need consistent water.")

    if season == "dry":
        tips.append("Irrigate every 2-3 days to keep soil moist but not waterlogged.")
    else:
        warnings.append("Heavy rain can wash away young seedlings. Check for erosion after storms.")

    if crop == "maize":
        tips.append(f"Day {dap}: Apply NPK 15:15:15 at 200kg/ha. Place 5cm from plant base.")
        tips.append("Thin to 2 plants per stand at 2-3 leaf stage.")
        warnings.append("Watch for cutworms at the base of young plants.")
    elif crop == "rice":
        tips.append(f"Day {dap}: Maintain 5cm water level in nursery." if dap < 21 else "Transplant seedlings to main field at 3 weeks.")
        tips.append("Space transplanted seedlings 20cm x 20cm.")
    elif crop == "cassava":
        tips.append("Plant cuttings at 45° angle with 2-3 nodes above ground.")
        tips.append("Space 1m x 1m for good tuber development.")
    elif crop == "tomato":
        tips.append("Transplant at 4-5 weeks. Space 60cm x 60cm.")
        tips.append("Install stakes for support before plants get too large.")
    else:
        tips.append(f"Day {dap}: Monitor emergence and fill any gaps by re-planting.")

    message = f"Your {crop} is in early growth stage (day {dap}). Focus on weed control and moisture management."
    return message, tips, warnings


def _vegetative_advice(crop: str, season: str, dap: int, pests: list):
    tips = []
    warnings = []

    tips.append("Plants are actively growing — nutrient demand is high.")
    tips.append("Monitor for pest damage on leaves. Early detection saves crops.")

    if season == "dry":
        tips.append("Apply irrigation if no rain in 3-4 days. Focus on root zone.")
    else:
        tips.append("Check drainage after heavy rains. Remove excess water if needed.")

    if crop == "maize":
        tips.append(f"Day {dap}: Apply Urea top-dressing at 200kg/ha. Side-dress 10cm from plants.")
        tips.append("Earth up (ridge) around stems for support and root development.")
        if "fall_armyworm" in pests:
            warnings.append("Scout for Fall Armyworm — check whorl leaves for frass and damage.")
    elif crop == "rice":
        tips.append(f"Day {dap}: Apply Urea 100kg/ha. Drain water, apply, then re-flood after 2 days.")
        tips.append("Control weeds manually or with approved herbicide.")
        warnings.append("Watch for rice blast — brown lesions on leaves indicate infection.")
    elif crop == "cassava":
        tips.append("Remove weeds manually. Cassava is sensitive to weed competition in first 3 months.")
        tips.append("Apply NPK 15:15:15 at 200kg/ha if not done earlier.")
        warnings.append("Check for cassava mosaic virus — distorted leaves with yellow patches.")
    elif crop == "cocoa":
        tips.append("Maintain shade. Prune lower branches for air circulation.")
        warnings.append("Check for black pod disease, especially in wet weather.")
    elif crop == "tomato":
        tips.append("Apply NPK 15:15:15 at 150kg/ha. Water regularly.")
        tips.append("Tie plants to stakes as they grow.")
        warnings.append("Watch for early blight — dark spots with concentric rings on lower leaves.")
    elif crop == "yam":
        tips.append("Provide stakes for yam vines to climb. This increases yield 2-3x.")
    else:
        tips.append(f"Day {dap}: Ensure adequate nutrients. Side-dress with NPK if needed.")

    risk = "low"
    if len(warnings) > 1:
        risk = "medium"

    message = (f"Vegetative growth phase — your {crop} needs nitrogen and weed control. "
               f"Apply recommended fertilizer and scout for pests daily.")
    return message, tips, warnings


def _reproductive_advice(crop: str, season: str, dap: int, pests: list):
    tips = []
    warnings = []
    risk = "low"

    tips.append("Critical growth stage — stress now directly reduces yield.")
    tips.append("Ensure adequate water and nutrients.")
    warnings.append("Pest pressure increases during this stage. Increase scouting frequency.")

    if crop == "maize":
        tips.append("Silking/tasseling stage. Ensure adequate soil moisture for grain fill.")
        tips.append("Apply potassium (MOP) at 100kg/ha for better grain filling.")
        warnings.append("Watch for stem borers — entry holes in stems cause lodging.")
        risk = "medium"
    elif crop == "rice":
        tips.append("Panicle initiation stage. Apply Urea 50kg/ha.")
        tips.append("Maintain 5-10cm water level until flowering.")
        warnings.append("Rice blast can infect panicles — causing blank grains.")
    elif crop == "cassava":
        tips.append("Tuber bulking stage. Potassium is critical now.")
        tips.append("Apply KCl (Muriate of Potash) at 100kg/ha.")
        risk = "medium"
    elif crop == "tomato":
        tips.append("Apply potassium-rich fertilizer for fruit development.")
        tips.append("Ensure consistent watering to prevent blossom end rot.")
        warnings.append("Late blight can destroy fruits rapidly. Apply fungicide preventively.")
        risk = "medium"
    elif crop == "cocoa":
        tips.append("Pod development. Remove infected pods to prevent spread.")
        warnings.append("Black pod disease spreads rapidly in wet conditions. Spray copper fungicide.")
        risk = "high"
    elif crop == "beans":
        tips.append("Flowering and pod set. Avoid nitrogen fertilizer now.")
        tips.append("Ensure bees and pollinators have access.")
        warnings.append("Pod borers can destroy developing seeds. Spray if seen.")
    else:
        tips.append(f"Day {dap}: Focus on water and potassium for good yield formation.")

    message = (f"Reproductive stage for your {crop}. This is the yield-determining phase — "
               f"water and pest management are critical.")
    return message, tips, warnings


def _maturation_advice(crop: str, season: str, dap: int):
    tips = []
    warnings = []

    tips.append("Crop is maturing. Reduce watering gradually.")
    tips.append("Monitor for birds and rodents which cause significant losses.")

    if crop in ("maize", "rice"):
        tips.append("Stop irrigation. Allow field to dry for harvest.")
        warnings.append("Harvest too early = low yield. Harvest too late = shattering losses.")
    elif crop in ("cassava", "yam", "sweet_potato"):
        tips.append("Tubers are maturing. Soil cracking indicates readiness.")
    elif crop in ("tomato", "pepper"):
        tips.append("Pick fruits as they ripen. Regular harvesting encourages more production.")
    elif crop == "onion":
        tips.append("Stop watering when tops begin to fall over. Lift bulbs when tops are dry.")

    message = f"Your {crop} is maturing. Prepare for harvest. Check crop readiness indicators daily."
    return message, tips, warnings


def _harvest_advice(crop: str, season: str):
    tips = []
    warnings = []

    tips.append("Prepare harvest tools and storage area.")
    tips.append("Harvest in dry weather for best quality.")
    warnings.append("Post-harvest losses in Nigeria average 30% — proper drying and storage is essential.")

    if crop == "maize":
        tips.append("Harvest when husks are brown and kernels are hard (<20% moisture).")
        tips.append("Dry cobs in well-ventilated area. Shell and store in hermetic bags.")
    elif crop == "rice":
        tips.append("Harvest at 20-25% moisture. Dry to 14% before storage.")
        tips.append("Use tarpaulins for drying — avoid roadside drying which contaminates grain.")
    elif crop == "cassava":
        tips.append("Harvest at 12-18 months. Cut stems 30cm above ground first.")
        tips.append("Process within 48 hours of harvest to prevent spoilage.")
    elif crop == "yam":
        tips.append("Harvest when vines turn yellow and die back. Dig carefully to avoid bruising.")
        tips.append("Store in cool, well-ventilated barn. Treat with fungicide before storage.")
    elif crop == "tomato":
        tips.append("Harvest at color break (pink stage) for longer shelf life.")

    message = f"Harvest time! Proper harvest and storage can reduce the 30% post-harvest losses common in Nigeria."
    return message, tips, warnings


# ── Helper ────────────────────────────────────────────────────────────────────

def _derive_actions(tips: list[str], warnings: list[str]) -> list[dict]:
    actions = []
    for w in warnings[:2]:
        actions.append({"text": f"⚠️ {w}", "priority": "high"})
    for t in tips[:3]:
        actions.append({"text": f"✅ {t}", "priority": "medium"})
    return actions


# ── Crop data ──────────────────────────────────────────────────────────────────

_CROP_STAGES = {
    "maize": {
        "duration": 120,
        "stages": [
            {"start": 0, "end": 7,    "name": "germination",   "label": "Germination"},
            {"start": 8, "end": 30,   "name": "vegetative",    "label": "Vegetative Growth"},
            {"start": 31, "end": 55,  "name": "tasseling",     "label": "Tasseling & Silking"},
            {"start": 56, "end": 90,  "name": "grain_fill",    "label": "Grain Fill"},
            {"start": 91, "end": 120, "name": "maturation",    "label": "Maturation"},
        ],
    },
    "rice": {
        "duration": 120,
        "stages": [
            {"start": 0, "end": 21,   "name": "nursery",       "label": "Nursery"},
            {"start": 22, "end": 45,  "name": "seedling",      "label": "Seedling / Tillering"},
            {"start": 46, "end": 70,  "name": "vegetative",    "label": "Vegetative Growth"},
            {"start": 71, "end": 85,  "name": "panicle",       "label": "Panicle Initiation"},
            {"start": 86, "end": 105, "name": "flowering",     "label": "Flowering & Grain Fill"},
            {"start": 106, "end": 120,"name": "maturation",    "label": "Maturation"},
        ],
    },
    "cassava": {
        "duration": 365,
        "stages": [
            {"start": 0, "end": 60,   "name": "establishment", "label": "Establishment"},
            {"start": 61, "end": 180, "name": "vegetative",    "label": "Vegetative Growth"},
            {"start": 181, "end": 270,"name": "tuber_bulking", "label": "Tuber Bulking"},
            {"start": 271, "end": 365,"name": "maturation",    "label": "Maturation"},
        ],
    },
    "yam": {
        "duration": 270,
        "stages": [
            {"start": 0, "end": 30,   "name": "sprouting",     "label": "Sprouting"},
            {"start": 31, "end": 120, "name": "vegetative",    "label": "Vegetative / Vine Growth"},
            {"start": 121, "end": 210,"name": "tuber_bulking", "label": "Tuber Bulking"},
            {"start": 211, "end": 270,"name": "maturation",    "label": "Maturation"},
        ],
    },
    "beans": {
        "duration": 90,
        "stages": [
            {"start": 0, "end": 14,   "name": "germination",   "label": "Germination"},
            {"start": 15, "end": 40,  "name": "vegetative",    "label": "Vegetative Growth"},
            {"start": 41, "end": 55,  "name": "flowering",     "label": "Flowering"},
            {"start": 56, "end": 70,  "name": "pod_development","label": "Pod Development"},
            {"start": 71, "end": 90,  "name": "maturation",    "label": "Maturation"},
        ],
    },
    "tomato": {
        "duration": 120,
        "stages": [
            {"start": 0, "end": 30,   "name": "nursery",       "label": "Nursery"},
            {"start": 31, "end": 50,  "name": "establishment", "label": "Establishment"},
            {"start": 51, "end": 75,  "name": "vegetative",    "label": "Vegetative Growth"},
            {"start": 76, "end": 90,  "name": "flowering",     "label": "Flowering & Fruiting"},
            {"start": 91, "end": 120, "name": "ripening",      "label": "Ripening"},
        ],
    },
    "sorghum": {
        "duration": 130,
        "stages": [
            {"start": 0, "end": 30,   "name": "seedling",      "label": "Seedling"},
            {"start": 31, "end": 60,  "name": "vegetative",    "label": "Vegetative / Tillering"},
            {"start": 61, "end": 80,  "name": "reproductive",  "label": "Flag Leaf / Boot"},
            {"start": 81, "end": 100, "name": "flowering",     "label": "Flowering / Grain Fill"},
            {"start": 101, "end": 130,"name": "maturation",    "label": "Maturation"},
        ],
    },
    "millet": {
        "duration": 105,
        "stages": [
            {"start": 0, "end": 20,   "name": "seedling",      "label": "Seedling"},
            {"start": 21, "end": 55,  "name": "vegetative",    "label": "Vegetative / Tillering"},
            {"start": 56, "end": 75,  "name": "flowering",     "label": "Flowering / Grain Fill"},
            {"start": 76, "end": 105, "name": "maturation",    "label": "Maturation"},
        ],
    },
    "groundnut": {
        "duration": 120,
        "stages": [
            {"start": 0, "end": 14,   "name": "germination",   "label": "Germination"},
            {"start": 15, "end": 50,  "name": "vegetative",    "label": "Vegetative Growth"},
            {"start": 51, "end": 70,  "name": "flowering",     "label": "Flowering / Pegging"},
            {"start": 71, "end": 120, "name": "pod_fill",      "label": "Pod Fill / Maturation"},
        ],
    },
    "cocoa": {
        "duration": 365,
        "stages": [
            {"start": 0, "end": 90,   "name": "establishment", "label": "Establishment"},
            {"start": 91, "end": 180, "name": "vegetative",    "label": "Vegetative Growth"},
            {"start": 181, "end": 270,"name": "flowering",     "label": "Flowering & Pod Set"},
            {"start": 271, "end": 365,"name": "pod_maturity",  "label": "Pod Maturation & Harvest"},
        ],
    },
    "onion": {
        "duration": 150,
        "stages": [
            {"start": 0, "end": 56,   "name": "nursery",       "label": "Nursery (8 weeks)"},
            {"start": 57, "end": 80,  "name": "establishment", "label": "Establishment"},
            {"start": 81, "end": 120, "name": "bulb_formation", "label": "Bulb Formation"},
            {"start": 121, "end": 150,"name": "maturation",    "label": "Maturation"},
        ],
    },
    "okra": {
        "duration": 70,
        "stages": [
            {"start": 0, "end": 10,   "name": "germination",   "label": "Germination"},
            {"start": 11, "end": 30,  "name": "vegetative",    "label": "Vegetative Growth"},
            {"start": 31, "end": 50,  "name": "flowering",     "label": "Flowering & Fruiting"},
            {"start": 51, "end": 70,  "name": "harvest",       "label": "Harvest"},
        ],
    },
    "pepper": {
        "duration": 120,
        "stages": [
            {"start": 0, "end": 35,   "name": "nursery",       "label": "Nursery"},
            {"start": 36, "end": 55,  "name": "establishment", "label": "Establishment"},
            {"start": 56, "end": 85,  "name": "vegetative",    "label": "Vegetative Growth"},
            {"start": 86, "end": 120, "name": "fruiting",      "label": "Flowering & Fruiting"},
        ],
    },
    "sweet_potato": {
        "duration": 150,
        "stages": [
            {"start": 0, "end": 14,   "name": "establishment", "label": "Establishment"},
            {"start": 15, "end": 60,  "name": "vegetative",    "label": "Vine Growth"},
            {"start": 61, "end": 120, "name": "tuber_bulking", "label": "Tuber Bulking"},
            {"start": 121, "end": 150,"name": "maturation",    "label": "Maturation"},
        ],
    },
    "cowpea": {
        "duration": 80,
        "stages": [
            {"start": 0, "end": 10,   "name": "germination",   "label": "Germination"},
            {"start": 11, "end": 35,  "name": "vegetative",    "label": "Vegetative Growth"},
            {"start": 36, "end": 50,  "name": "flowering",     "label": "Flowering"},
            {"start": 51, "end": 80,  "name": "pod_fill",      "label": "Pod Fill / Maturation"},
        ],
    },
    "soya_beans": {
        "duration": 100,
        "stages": [
            {"start": 0, "end": 10,   "name": "germination",   "label": "Germination"},
            {"start": 11, "end": 40,  "name": "vegetative",    "label": "Vegetative Growth"},
            {"start": 41, "end": 55,  "name": "flowering",     "label": "Flowering"},
            {"start": 56, "end": 75,  "name": "pod_fill",      "label": "Pod Fill"},
            {"start": 76, "end": 100, "name": "maturation",    "label": "Maturation"},
        ],
    },
    "ginger": {
        "duration": 240,
        "stages": [
            {"start": 0, "end": 30,   "name": "sprouting",     "label": "Sprouting"},
            {"start": 31, "end": 120, "name": "vegetative",    "label": "Vegetative Growth"},
            {"start": 121, "end": 180,"name": "rhizome_bulking","label": "Rhizome Bulking"},
            {"start": 181, "end": 240,"name": "maturation",    "label": "Maturation"},
        ],
    },
    "water_melon": {
        "duration": 90,
        "stages": [
            {"start": 0, "end": 10,   "name": "germination",   "label": "Germination"},
            {"start": 11, "end": 35,  "name": "vegetative",    "label": "Vine Growth"},
            {"start": 36, "end": 50,  "name": "flowering",     "label": "Flowering & Fruit Set"},
            {"start": 51, "end": 90,  "name": "fruit_maturation","label": "Fruit Maturation"},
        ],
    },
    "sesame": {
        "duration": 105,
        "stages": [
            {"start": 0, "end": 15,   "name": "germination",   "label": "Germination"},
            {"start": 16, "end": 45,  "name": "vegetative",    "label": "Vegetative Growth"},
            {"start": 46, "end": 65,  "name": "flowering",     "label": "Flowering & Capsule Set"},
            {"start": 66, "end": 105, "name": "maturation",    "label": "Capsule Maturation"},
        ],
    },
    "garden_egg": {
        "duration": 90,
        "stages": [
            {"start": 0, "end": 35,   "name": "nursery",       "label": "Nursery"},
            {"start": 36, "end": 55,  "name": "establishment", "label": "Establishment"},
            {"start": 56, "end": 90,  "name": "fruiting",      "label": "Flowering & Fruiting"},
        ],
    },
}

_CROP_INFO = {
    "maize":       {"name": "Maize",     "emoji": "🌽", "common_pests": ["fall_armyworm", "stem_borer", "maize_streak_virus"]},
    "rice":        {"name": "Rice",      "emoji": "🍚", "common_pests": ["rice_blast", "stem_borer", "rice_gall_midge"]},
    "cassava":     {"name": "Cassava",   "emoji": "🌿", "common_pests": ["cassava_mosaic", "cassava_green_mite", "mealybug"]},
    "yam":         {"name": "Yam",       "emoji": "🍠", "common_pests": ["yam_mosaic", "scorch", "nematodes"]},
    "beans":       {"name": "Beans",     "emoji": "🫘", "common_pests": ["aphids", "pod_borer", "bean_fly"]},
    "millet":      {"name": "Millet",    "emoji": "🌾", "common_pests": ["head_miner", "stem_borer", "downy_mildew"]},
    "sorghum":     {"name": "Sorghum",   "emoji": "🌾", "common_pests": ["stem_borer", "midge", "sorghum_downy_mildew"]},
    "groundnut":   {"name": "Groundnut", "emoji": "🥜", "common_pests": ["leaf_spot", "rosette_virus", "aphids"]},
    "cocoa":       {"name": "Cocoa",     "emoji": "🍫", "common_pests": ["black_pod", "mirid", "swollen_shoot_virus"]},
    "tomato":      {"name": "Tomato",    "emoji": "🍅", "common_pests": ["late_blight", "early_blight", "whitefly"]},
    "onion":       {"name": "Onion",     "emoji": "🧅", "common_pests": ["thrips", "downy_mildew", "purple_blotch"]},
    "okra":        {"name": "Okra",      "emoji": "🫘", "common_pests": ["okra_mosaic", "leaf_hopper", "fruit_borer"]},
    "garden_egg":  {"name": "Garden Egg","emoji": "🍆", "common_pests": ["leaf_hopper", "fruit_borer", "aphids"]},
    "pepper":      {"name": "Pepper",    "emoji": "🌶️", "common_pests": ["anthracnose", "whitefly", "thrips"]},
    "water_melon": {"name": "Water Melon","emoji": "🍉", "common_pests": ["powdery_mildew", "anthracnose", "aphids"]},
    "sweet_potato":{"name": "Sweet Potato","emoji":"🍠", "common_pests": ["sweet_potato_weevil", "scab", "virus"]},
    "cowpea":      {"name": "Cowpea",    "emoji": "🫘", "common_pests": ["aphids", "thrips", "pod_borer"]},
    "soya_beans":  {"name": "Soya Beans","emoji": "🫘", "common_pests": ["soybean_rust", "pod_borer", "whitefly"]},
    "ginger":      {"name": "Ginger",    "emoji": "🫚", "common_pests": ["ginger_blight", "root_knot_nematode", "leaf_spot"]},
    "sesame":      {"name": "Sesame",    "emoji": "🌱", "common_pests": ["sesame_leaf_spot", "aphids", "webworm"]},
}
