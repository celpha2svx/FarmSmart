"""
FarmSmart Market Price Scraper.

Sources:
1. AFEX Exchange API (free) — live commodity securities prices
2. commodity.ng — scraped grain/vegetable prices
3. farmlink.ng — detailed value chain prices

All prices are cached in the MarketPrice table.
"""

import logging
from datetime import datetime
from typing import Optional

import httpx

from utils.config import settings

logger = logging.getLogger(__name__)

# ── AFEX API ─────────────────────────────────────────────────────────────────

AFEX_SECURITIES = {
    "SMAZ": "maize",
    "SBBS": "beans",
    "SPCM": "paddy_rice",
    "SSOY": "soya_beans",
    "SSGH": "sorghum",
    "SMLT": "millet",
    "SGNG": "groundnut",
    "SCOC": "cocoa",
    "SGNR": "ginger",
    "SSES": "sesame",
}

CROP_TO_AFEX = {v: k for k, v in AFEX_SECURITIES.items()}


async def fetch_afex_prices() -> list[dict]:
    """Fetch live commodity prices from AFEX Exchange API."""
    url = f"{settings.afex_api_base}/securities/info"
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(url)
            resp.raise_for_status()
            data = resp.json()
    except Exception as e:
        logger.warning(f"AFEX API error: {e}")
        return []

    prices = []
    today = datetime.utcnow().strftime("%Y-%m-%d")
    for item in data if isinstance(data, list) else data.get("data", [data]):
        code = item.get("code", "")
        crop = AFEX_SECURITIES.get(code)
        if not crop:
            continue
        price_str = item.get("current_price", "0")
        try:
            price_ngn = float(price_str)
        except (ValueError, TypeError):
            continue

        # AFEX prices are per tonne; convert to per 50kg bag
        price_per_50kg = round(price_ngn * 50 / 1000, 2)

        prices.append({
            "crop": crop,
            "market": "AFEX Exchange",
            "price_ngn": price_per_50kg,
            "unit": "50 kg bag",
            "price_date": today,
            "source": "afex",
        })

    logger.info(f"Fetched {len(prices)} prices from AFEX API")
    return prices


# ── commodity.ng scraper ─────────────────────────────────────────────────────

COMMODITY_NG_MAP = {
    "rice": "Rice", "maize": "Maize", "beans": "Beans",
    "soya_beans": "Soya Beans", "millet": "Millet",
    "sorghum": "Sorghum", "garri": "Garri",
    "tomatoes": "Tomatoes", "onion": "Onion",
    "groundnut": "Groundnut", "cassava": "Cassava",
    "yam": "Yam", "cocoa": "Cocoa", "ginger": "Ginger",
    "sesame": "Sesame", "sweet_potato": "Sweet Potato",
}


async def fetch_commodity_ng_prices() -> list[dict]:
    """Scrape live prices from commodity.ng."""
    from bs4 import BeautifulSoup
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            resp = await client.get("https://commodity.ng/live-prices/")
            resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "lxml")
    except Exception as e:
        logger.warning(f"commodity.ng scrape failed: {e}")
        return []

    prices = []
    today = datetime.utcnow().strftime("%Y-%m-%d")

    # Try to extract table data
    tables = soup.find_all("table")
    for table in tables:
        rows = table.find_all("tr")
        for row in rows:
            cells = row.find_all("td")
            if len(cells) < 3:
                continue
            name_cell = cells[0].get_text(strip=True).lower()
            # Find which crop this matches
            for crop_key, display_name in COMMODITY_NG_MAP.items():
                if display_name.lower() in name_cell or crop_key in name_cell:
                    # Try to extract price from the "Price of 50kg" column or current price
                    price_text = ""
                    for cell in cells[1:]:
                        text = cell.get_text(strip=True).replace("₦", "").replace(",", "")
                        try:
                            float(text)
                            price_text = text
                            break
                        except ValueError:
                            continue
                    if price_text:
                        try:
                            price_ngn = float(price_text)
                            prices.append({
                                "crop": crop_key,
                                "market": "National Average (commodity.ng)",
                                "price_ngn": price_ngn,
                                "unit": "50 kg bag",
                                "price_date": today,
                                "source": "commodity.ng",
                            })
                        except ValueError:
                            pass
                    break

    logger.info(f"Scraped {len(prices)} prices from commodity.ng")
    return prices


# ── Top-level scraper ────────────────────────────────────────────────────────

async def scrape_all_prices() -> list[dict]:
    """Fetch prices from all sources and merge."""
    all_prices = []

    afex = await fetch_afex_prices()
    all_prices.extend(afex)

    commodity = await fetch_commodity_ng_prices()
    all_prices.extend(commodity)

    if not all_prices:
        logger.warning("All market price sources failed — returning fallback prices")
        all_prices = _get_fallback_prices()

    return all_prices


def _get_fallback_prices() -> list[dict]:
    """Return recent known prices when all sources fail."""
    today = datetime.utcnow().strftime("%Y-%m-%d")
    return [
        {"crop": "maize",      "market": "Dawanau (Kano)",        "price_ngn": 38500, "unit": "50 kg bag", "price_date": today, "source": "fallback"},
        {"crop": "rice",       "market": "Mile 12 (Lagos)",       "price_ngn": 57000, "unit": "50 kg bag", "price_date": today, "source": "fallback"},
        {"crop": "beans",      "market": "Bodija (Ibadan)",       "price_ngn": 40000, "unit": "50 kg bag", "price_date": today, "source": "fallback"},
        {"crop": "soya_beans", "market": "AFEX Exchange",        "price_ngn": 41000, "unit": "50 kg bag", "price_date": today, "source": "fallback"},
        {"crop": "sorghum",    "market": "Kurmi (Jos)",           "price_ngn": 35000, "unit": "50 kg bag", "price_date": today, "source": "fallback"},
        {"crop": "millet",     "market": "Dawanau (Kano)",        "price_ngn": 34500, "unit": "50 kg bag", "price_date": today, "source": "fallback"},
        {"crop": "groundnut",  "market": "AFEX Exchange",        "price_ngn": 45000, "unit": "50 kg bag", "price_date": today, "source": "fallback"},
        {"crop": "cassava",    "market": "Ogbete (Enugu)",        "price_ngn": 29000, "unit": "50 kg bag", "price_date": today, "source": "fallback"},
        {"crop": "yam",        "market": "Zaria (Kaduna)",        "price_ngn": 35000, "unit": "50 kg bag", "price_date": today, "source": "fallback"},
        {"crop": "tomato",     "market": "Mile 12 (Lagos)",       "price_ngn": 56000, "unit": "basket",     "price_date": today, "source": "fallback"},
        {"crop": "onion",      "market": "Dawanau (Kano)",        "price_ngn": 48000, "unit": "basket",     "price_date": today, "source": "fallback"},
        {"crop": "cocoa",      "market": "AFEX Exchange",        "price_ngn": 85000, "unit": "50 kg bag", "price_date": today, "source": "fallback"},
        {"crop": "ginger",     "market": "AFEX Exchange",        "price_ngn": 38000, "unit": "50 kg bag", "price_date": today, "source": "fallback"},
    ]
