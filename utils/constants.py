# FarmSmart — Agronomic Constants
# Soil moisture thresholds per crop (m³/m³)
# Below 'critical' → IRRIGATE IMMEDIATELY
# Below 'low'      → Irrigate within 24 hours
SOIL_THRESHOLDS = {
    # Existing crops
    "maize":        {"critical": 0.15, "low": 0.20},
    "cassava":      {"critical": 0.10, "low": 0.15},
    "tomato":       {"critical": 0.18, "low": 0.23},
    "rice":         {"critical": 0.30, "low": 0.35},
    "yam":          {"critical": 0.12, "low": 0.18},
    # New vegetables
    "pepper":       {"critical": 0.18, "low": 0.23},
    "okra":         {"critical": 0.12, "low": 0.17},
    "onion":        {"critical": 0.20, "low": 0.25},
    "watermelon":   {"critical": 0.15, "low": 0.20},
    # New grains & legumes
    "sorghum":      {"critical": 0.10, "low": 0.15},
    "millet":       {"critical": 0.08, "low": 0.13},
    "groundnut":    {"critical": 0.10, "low": 0.15},
    "cowpea":       {"critical": 0.10, "low": 0.15},
    "soybean":      {"critical": 0.15, "low": 0.20},
    # New tubers & roots
    "sweet_potato": {"critical": 0.10, "low": 0.15},
    "ginger":       {"critical": 0.15, "low": 0.20},
    # New cash / tree crops
    "cocoa":        {"critical": 0.18, "low": 0.23},
    "oil_palm":     {"critical": 0.18, "low": 0.23},
    "plantain":     {"critical": 0.18, "low": 0.23},
    "sesame":       {"critical": 0.10, "low": 0.15},
}

# Pest degree-day models
# base_temp: minimum temperature for pest development (°C)
# dd_threshold: accumulated degree-days before pest emergence
PEST_CONFIG = {
    # Existing pests
    "fall_armyworm":     {"name": "Fall Armyworm",      "base_temp": 12.0, "dd_threshold": 350},
    "desert_locust":     {"name": "Desert Locust",      "base_temp": 15.0, "dd_threshold": 400},
    "stem_borer":        {"name": "Maize Stem Borer",   "base_temp": 10.0, "dd_threshold": 250},
    "tomato_blight":     {"name": "Tomato Late Blight", "base_temp":  7.0, "dd_threshold": 150},
    # New insect pests
    "aphids":            {"name": "Aphids",             "base_temp":  5.0, "dd_threshold": 150},
    "thrips":            {"name": "Thrips",             "base_temp": 10.0, "dd_threshold": 200},
    "whiteflies":        {"name": "Whiteflies",         "base_temp": 10.0, "dd_threshold": 300},
    "mealybugs":         {"name": "Mealybugs",          "base_temp": 12.0, "dd_threshold": 350},
    "cowpea_pod_borer":  {"name": "Cowpea Pod Borer",   "base_temp": 11.0, "dd_threshold": 400},
    "spider_mites":      {"name": "Spider Mites",       "base_temp": 12.0, "dd_threshold": 250},
    "leaf_miners":       {"name": "Leaf Miners",        "base_temp":  8.0, "dd_threshold": 200},
    "cassava_green_mite":{"name": "Cassava Green Mite", "base_temp": 12.0, "dd_threshold": 300},
    "banana_weevil":     {"name": "Banana Weevil",      "base_temp": 10.0, "dd_threshold": 350},
    "yam_beetle":        {"name": "Yam Beetle",         "base_temp": 12.0, "dd_threshold": 400},
    "grain_weevil":      {"name": "Grain Weevil",       "base_temp": 10.0, "dd_threshold": 500},
    # New fungal / disease
    "black_pod":         {"name": "Black Pod Disease",  "base_temp":  8.0, "dd_threshold": 200},
    "root_knot_nematode":{"name": "Root Knot Nematode", "base_temp": 10.0, "dd_threshold": 500},
}

# Crop → relevant pests mapping
CROP_PESTS = {
    # Grains
    "maize":        ["fall_armyworm", "stem_borer", "desert_locust", "grain_weevil"],
    "rice":         ["stem_borer", "fall_armyworm", "grain_weevil"],
    "sorghum":      ["stem_borer", "fall_armyworm", "grain_weevil"],
    "millet":       ["stem_borer", "fall_armyworm", "grain_weevil"],
    # Legumes
    "groundnut":    ["aphids", "leaf_miners", "spider_mites", "fall_armyworm"],
    "cowpea":       ["cowpea_pod_borer", "aphids", "thrips", "spider_mites"],
    "soybean":      ["cowpea_pod_borer", "aphids", "spider_mites", "fall_armyworm"],
    # Tubers & roots
    "cassava":      ["fall_armyworm", "cassava_green_mite", "whiteflies", "mealybugs"],
    "yam":          ["fall_armyworm", "yam_beetle", "mealybugs", "leaf_miners"],
    "sweet_potato": ["whiteflies", "weevils", "leaf_miners"],
    "ginger":       ["root_knot_nematode", "leaf_miners"],
    # Vegetables
    "tomato":       ["tomato_blight", "aphids", "whiteflies", "spider_mites", "root_knot_nematode"],
    "pepper":       ["aphids", "thrips", "whiteflies", "spider_mites", "root_knot_nematode", "leaf_miners"],
    "okra":         ["aphids", "whiteflies", "spider_mites", "fall_armyworm"],
    "onion":        ["thrips", "whiteflies"],
    "watermelon":   ["aphids", "spider_mites", "leaf_miners"],
    # Cash / tree crops
    "cocoa":        ["black_pod", "mealybugs", "aphids"],
    "oil_palm":     ["leaf_miners", "weevils"],
    "plantain":     ["banana_weevil", "mealybugs", "black_pod"],
    "sesame":       ["aphids", "whiteflies", "leaf_miners"],
}

# Crop categories for registration UI grouping
CROP_CATEGORIES = {
    "grains":       ["maize", "rice", "sorghum", "millet"],
    "legumes":      ["groundnut", "cowpea", "soybean"],
    "tubers_roots": ["cassava", "yam", "sweet_potato", "ginger"],
    "vegetables":   ["tomato", "pepper", "okra", "onion", "watermelon"],
    "cash_tree":    ["cocoa", "oil_palm", "plantain", "sesame"],
}

# All crop IDs in display order
ALL_CROPS = [
    "maize", "rice", "sorghum", "millet",
    "groundnut", "cowpea", "soybean",
    "cassava", "yam", "sweet_potato", "ginger",
    "tomato", "pepper", "okra", "onion", "watermelon",
    "cocoa", "oil_palm", "plantain", "sesame",
]

# Degree-day risk thresholds (% of dd_threshold)
DD_RISK_HIGH   = 80
DD_RISK_MEDIUM = 60
DD_RISK_LOW    = 40

# Daily alert send time (local Nigeria time)
DAILY_ALERT_HOUR = 6   # 6 AM WAT

# Open-Meteo base URL
OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"

# WhatsApp Graph API version
WA_API_VERSION = "v18.0"