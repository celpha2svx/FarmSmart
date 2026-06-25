"""
Geocoding — Nigerian LGA and town names → latitude/longitude.

Strategy:
  1. Check the local LGA lookup table (fast, no network call).
  2. Fall back to Open-Meteo Geocoding API (free, no key needed).

Organised by geopolitical zone for maintainability.
Covers 36 states + FCT with major farming LGAs.
"""

import httpx
import logging
from typing import Optional, Tuple

logger = logging.getLogger(__name__)

# ── North West ──────────────────────────────────────────────────────────────────
# Kaduna, Kano, Katsina, Jigawa, Kebbi, Sokoto, Zamfara
NW = {
    # Kaduna State
    "sabon gari":      (11.1023, 7.7174),
    "kaduna north":    (10.5234, 7.4370),
    "kaduna south":    (10.4800, 7.4300),
    "zaria":           (11.0780, 7.7020),
    "kafanchan":       (9.5770, 8.2910),
    "giwa":            (11.1430, 7.1870),
    "ikara":           (10.3400, 7.5500),
    "sanga":           (9.2950, 8.3830),
    # Kano State
    "kano":            (12.0022, 8.5920),
    "bunkure":         (11.7170, 8.8500),
    "rogo":            (11.5820, 8.7830),
    "garun mallam":    (11.6833, 8.3667),
    "gaya":            (11.8570, 9.0020),
    "wudil":           (11.8290, 8.8380),
    "dawakin tofa":    (12.0000, 8.3167),
    # Katsina State
    "katsina":         (12.9863, 7.6170),
    "daura":           (13.0356, 8.3239),
    "funtua":          (11.5210, 7.3110),
    "malumfashi":      (11.7890, 7.6170),
    "jibia":           (12.5630, 7.2170),
    # Jigawa State
    "dutse":           (11.7594, 9.3420),
    "hadejia":         (12.4500, 10.0333),
    "gumel":           (12.6260, 9.3830),
    "kazaure":         (12.6440, 8.4090),
    "birnin kudu":     (11.4500, 9.4800),
    # Kebbi State
    "birnin kebbi":    (12.4539, 4.1975),
    "argungu":         (12.7333, 4.5333),
    "yauri":           (10.9333, 4.8000),
    "zuru":            (11.4333, 5.2333),
    "koko besse":      (11.0970, 4.4210),
    # Sokoto State
    "sokoto":          (13.0622, 5.2339),
    "wurno":           (13.0500, 5.4333),
    "gwadabawa":       (13.0167, 5.2833),
    "tambuwal":        (12.4000, 4.6500),
    "yabo":            (12.7500, 5.0000),
    # Zamfara State
    "gusau":           (12.1704, 6.6640),
    "anka":            (12.0500, 5.9333),
    "talata mafara":   (12.3500, 6.0667),
    "shinkafi":        (12.5000, 6.2500),
    "bakura":          (12.6500, 5.8667),
}

# ── North East ──────────────────────────────────────────────────────────────────
# Adamawa, Bauchi, Borno, Gombe, Taraba, Yobe
NE = {
    # Adamawa State
    "yola":            (9.2035, 12.4954),
    "mubi":            (10.2670, 13.2670),
    "numan":           (9.4500, 12.0333),
    "gombi":           (10.1667, 12.7333),
    "hong":            (10.2333, 12.9333),
    # Bauchi State
    "bauchi":          (10.3158, 9.8442),
    "misau":           (11.3167, 10.4667),
    "azare":           (11.6833, 10.1833),
    "katagum":         (12.2833, 10.3333),
    "ningi":           (11.0667, 9.5667),
    # Borno State
    "maiduguri":       (11.8311, 13.1510),
    "bama":            (11.5150, 13.6890),
    "biu":             (10.6110, 12.1950),
    "dikwa":           (12.0333, 13.9167),
    "gwoza":           (11.0833, 13.6833),
    # Gombe State
    "gombe":           (10.2897, 11.1673),
    "kaltungo":        (10.4167, 11.3000),
    "billiri":         (10.1167, 11.2167),
    "akko":            (10.0500, 10.9167),
    "yamaltu deba":    (10.2000, 11.3500),
    # Taraba State
    "jalingo":         (8.8844, 11.3645),
    "wukari":          (7.8667, 9.7833),
    "takum":           (7.2667, 9.9833),
    "ibal":            (7.0167, 9.7000),
    "dong a":          (8.0833, 10.7667),
    # Yobe State
    "damaturu":        (11.7504, 11.9608),
    "potiskum":        (11.7130, 11.0810),
    "nguru":           (12.8833, 10.4500),
    "gashua":          (12.8690, 11.0480),
    "geidam":          (12.8833, 11.8000),
}

# ── North Central ───────────────────────────────────────────────────────────────
# Benue, Kogi, Kwara, Nasarawa, Niger, Plateau, FCT
NC = {
    # Benue State
    "makurdi":         (7.7400, 8.5200),
    "gboko":           (7.3200, 9.0000),
    "otukpo":          (7.1833, 8.1333),
    "katsina ala":     (7.1667, 9.2833),
    "vandeikya":       (6.7833, 9.0667),
    "kwande":          (7.0167, 9.3000),
    # Kogi State
    "lokoja":          (7.8000, 6.7333),
    "kabba":           (7.7833, 6.0667),
    "okene":           (7.5500, 6.2333),
    "anaku":           (7.1667, 6.6667),
    "idah":            (7.0833, 6.7333),
    # Kwara State
    "ilorin":          (8.5373, 4.5444),
    "offa":            (8.1500, 4.7167),
    "patigi":          (8.7333, 5.7500),
    "kaiama":          (9.6000, 3.9333),
    "baruten":         (9.2667, 3.7500),
    # Nasarawa State
    "lafia":           (8.4942, 8.5162),
    "keffi":           (8.8500, 7.8667),
    "akwanga":         (8.9167, 8.4000),
    "karu":            (8.9833, 7.6333),
    "doma":            (8.3833, 8.3333),
    # Niger State
    "minna":           (9.6139, 6.5569),
    "bida":            (9.0800, 6.0133),
    "suleja":          (9.1800, 7.1830),
    "kontagora":       (10.4000, 5.4667),
    "new bussa":       (9.8833, 4.5000),
    "lapai":           (9.0500, 6.5667),
    # Plateau State
    "jos north":       (9.9285, 8.8921),
    "jos south":       (9.7974, 8.8765),
    "barkin ladi":     (9.5333, 8.9000),
    "pankshin":        (9.3500, 9.4333),
    "shendam":         (8.8833, 9.5333),
    "mangu":           (9.5167, 9.1000),
    # FCT Abuja
    "abuja":           (9.0765, 7.3986),
    "gwagwalada":      (8.9500, 7.0833),
    "kuje":            (8.8833, 7.2167),
    "bwari":           (9.2833, 7.3833),
    "kwali":           (8.8833, 7.0000),
}

# ── South West ──────────────────────────────────────────────────────────────────
# Ekiti, Lagos, Ogun, Ondo, Osun, Oyo
SW = {
    # Ekiti State
    "ado ekiti":       (7.6212, 5.2210),
    "ikere ekiti":     (7.5000, 5.2333),
    "oye":             (7.7000, 5.4000),
    "idore":           (7.6833, 5.1167),
    "ikole":           (7.5000, 5.5167),
    # Lagos State
    "lagos":           (6.5244, 3.3792),
    "ikorodu":         (6.6194, 3.5053),
    "badagry":         (6.4167, 2.8833),
    "epe":             (6.5833, 3.9833),
    "ibejulekki":      (6.4667, 3.6000),
    # Ogun State
    "abeokuta":        (7.1475, 3.3619),
    "ijebu ode":       (6.8198, 3.9203),
    "sagamu":          (6.8366, 3.6486),
    "ileru":           (7.2300, 3.3000),
    "owo":             (7.1900, 3.3800),
    "shagamu":         (6.8366, 3.6486),
    # Ondo State
    "akure":           (7.2528, 5.1931),
    "ondo":            (7.0833, 4.8333),
    "owo":             (7.1833, 5.5833),
    "okitipupa":       (6.5000, 4.7833),
    "ile oluji":       (7.2167, 5.2167),
    # Osun State
    "osogbo":          (7.7667, 4.5667),
    "ilesa":           (7.6333, 4.7333),
    "ife":             (7.4833, 4.5500),
    "ila orangun":     (8.0167, 4.9000),
    "ede":             (7.7333, 4.4333),
    # Oyo State
    "oyo east":        (7.8500, 3.9300),
    "ibadan north":    (7.3775, 3.9470),
    "ogbomoso":        (8.1330, 4.2500),
    "saki":            (8.6670, 3.3930),
    "iseyin":          (7.9667, 3.6000),
    "kishi":           (9.0833, 3.8500),
}

# ── South East ──────────────────────────────────────────────────────────────────
# Abia, Anambra, Ebonyi, Enugu, Imo
SE = {
    # Abia State
    "umuahia":         (5.5314, 7.4853),
    "aba":             (5.1167, 7.3667),
    "ohafia":          (5.6167, 7.8333),
    "arochukwu":       (5.3833, 7.5167),
    "bende":           (5.5667, 7.6333),
    # Anambra State
    "awka":            (6.2088, 7.0686),
    "onitsha":         (6.1630, 6.7880),
    "nnewi":           (6.0167, 6.9167),
    "ekwulobia":       (5.9667, 7.0833),
    "awgbu":           (6.1167, 6.9833),
    # Ebonyi State
    "abakaliki":       (6.3249, 8.1137),
    "afikpo":          (5.8833, 7.9333),
    "ishielu":         (6.2833, 7.9833),
    "ezza":            (6.1333, 8.0167),
    "ikwo":            (6.2000, 8.1167),
    # Enugu State
    "enugu north":     (6.4483, 7.5139),
    "enugu east":      (6.4300, 7.5600),
    "nsukka":          (6.8500, 7.3833),
    "awgu":            (6.0833, 7.4667),
    "udi":             (6.3167, 7.4333),
    # Imo State
    "owerri":          (5.4836, 7.0333),
    "orlu":            (5.8000, 7.0333),
    "okigwe":          (5.8333, 7.3500),
    "mbano":           (5.6833, 7.1500),
    "oguta":           (5.7000, 6.7833),
}

# ── South South ──────────────────────────────────────────────────────────────────
# Akwa Ibom, Bayelsa, Cross River, Delta, Edo, Rivers
SS = {
    # Akwa Ibom State
    "uyo":             (5.0479, 7.9236),
    "ikot ekpene":     (5.1833, 7.7167),
    "etinan":          (4.8500, 7.8833),
    "ikono":           (5.1333, 7.7333),
    "orin":            (4.7667, 8.0000),
    # Bayelsa State
    "yenagoa":         (4.9167, 6.2667),
    "brass":           (4.3167, 6.2333),
    "sagbama":         (5.1500, 6.2000),
    "east oloibiri":   (4.8000, 6.2000),
    # Cross River State
    "calabar":         (4.9517, 8.3220),
    "ogoja":           (6.6500, 8.8000),
    "ikom":            (5.9667, 8.7167),
    "obubra":          (6.0833, 8.3333),
    "akamkpa":         (5.3167, 8.3500),
    # Delta State
    "asaba":           (6.1986, 6.7330),
    "warri":           (5.5167, 5.7500),
    "sapele":          (5.9000, 5.6667),
    "ughelli":         (5.5000, 6.0000),
    "agbor":           (6.2833, 6.1667),
    # Edo State
    "benin city":      (6.3176, 5.6145),
    "auchi":           (7.0667, 6.2667),
    "ekpoma":          (6.7500, 6.1333),
    "igbobazu":        (6.3500, 6.0000),
    "uhumwonde":       (6.3500, 5.8500),
    # Rivers State
    "port harcourt":   (4.7770, 7.0134),
    "bonny":           (4.4333, 7.1667),
    "okrika":          (4.7333, 7.0667),
    "etche":           (4.9833, 7.0667),
    "ahoada":          (5.0833, 6.6500),
}

# Merge all zones into single lookup table
NIGERIA_LGA_COORDS: dict[str, Tuple[float, float]] = {}
for zone in (NW, NE, NC, SW, SE, SS):
    NIGERIA_LGA_COORDS.update(zone)


def resolve_location(location_str: str) -> Optional[Tuple[float, float]]:
    """
    Resolve a location string (LGA or town name) to (latitude, longitude).
    Returns None if the location cannot be resolved.
    """
    key = location_str.strip().lower()

    # 1. Local lookup
    if key in NIGERIA_LGA_COORDS:
        logger.debug(f"Location '{location_str}' resolved from local table")
        return NIGERIA_LGA_COORDS[key]

    # 2. Partial match on local table (e.g. 'Sabon Gari, Kaduna' → 'sabon gari')
    for lga, coords in NIGERIA_LGA_COORDS.items():
        if lga in key or key in lga:
            logger.debug(f"Location '{location_str}' partial-matched to '{lga}'")
            return coords

    # 3. Geocoding API fallback (Open-Meteo Geocoding — free, no key)
    return _geocode_api(location_str)


def _geocode_api(location_str: str) -> Optional[Tuple[float, float]]:
    """Call the Open-Meteo geocoding API as a fallback."""
    try:
        url = "https://geocoding-api.open-meteo.com/v1/search"
        params = {"name": location_str, "count": 1, "language": "en", "format": "json"}
        response = httpx.get(url, params=params, timeout=10)
        response.raise_for_status()
        results = response.json().get("results", [])
        if results:
            r = results[0]
            lat, lon = r["latitude"], r["longitude"]
            logger.info(f"Geocoded '{location_str}' → ({lat}, {lon}) via API")
            return (lat, lon)
    except Exception as e:
        logger.error(f"Geocoding API failed for '{location_str}': {e}")

    return None