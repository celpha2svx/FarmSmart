# FarmSmart 🌱
**Precision Agriculture Advisory Platform for Smallholder Farmers in Nigeria**

> *Farm smart, no be guesswork.* 🇳🇬

FarmSmart delivers satellite-driven soil moisture forecasts, hyper-local weather advice, and pest early warnings directly to farmers via WhatsApp and SMS — at zero operating cost.

---

## How It Works

```
NASA SMAP / Open-Meteo  →  Processing Engine  →  WhatsApp / SMS
(Satellite + Weather)       (ET₀ · Pest DD)       (Plain language)
```

1. **Every 6 hours** — satellite soil moisture and weather forecast data is fetched for all registered farm locations
2. **Processing** — ET₀ (Penman-Monteith) and pest degree-day models run against fresh data
3. **6 AM daily** — each subscribed farmer receives a personalised report in plain English

---

## Quick Start

### 1. Clone and install
```bash
git clone https://github.com/your-org/farmsmart.git
cd farmsmart
pip install -r requirements.txt
```

### 2. Configure environment
```bash
cp .env.example .env
# Edit .env with your WhatsApp token, phone number ID, and DB URL
```

### 3. Run locally
```bash
python main.py
# Server starts at http://localhost:8000
```

### 4. Run tests
```bash
pytest tests/ -v
```

---

## Project Structure

```
farmsmart/
├── main.py                      # FastAPI app + WhatsApp webhook
├── requirements.txt
├── .env.example
│
├── data_pipeline/
│   ├── fetchers/
│   │   ├── soil_moisture.py     # NASA SMAP / Open-Meteo soil
│   │   ├── weather.py           # Open-Meteo 7-day forecast
│   │   └── elevation.py         # SRTM elevation (lapse-rate correction)
│   ├── models/
│   │   ├── penman_monteith.py   # FAO-56 ET₀ calculation
│   │   ├── soil_trend.py        # 3-day soil moisture projection
│   │   └── pest_models.py       # Degree-day pest accumulation
│   └── scheduler.py             # APScheduler cron jobs
│
├── translation/
│   ├── soil_to_message.py       # Soil data → farmer message
│   ├── weather_to_message.py    # Weather data → farmer message
│   └── pest_to_message.py       # Pest risk → alert + signs + scout guide
│
├── bot/
│   ├── whatsapp_handler.py      # Meta WhatsApp Cloud API
│   ├── sms_handler.py           # Africa's Talking SMS fallback
│   ├── registration.py          # 3-question onboarding flow
│   └── commands.py              # SOIL / WEATHER / PEST / etc.
│
├── database/
│   ├── models.py                # SQLAlchemy ORM (farmers, alerts, degree_days)
│   └── operations.py            # CRUD operations
│
├── tests/                       # pytest test suite
└── utils/
    ├── constants.py             # Crop thresholds, pest config
    ├── geocoding.py             # Nigerian LGA → lat/lon
    └── helpers.py               # Shared utilities
```

---

## WhatsApp Commands

| Command   | Response |
|-----------|----------|
| `SOIL`    | Soil moisture status + 3-day trend + irrigation advice |
| `WEATHER` | 3-day local forecast + spray/harvest/irrigate tips |
| `PEST`    | Pest risk level for registered crop |
| `DAILY`   | Subscribe to 6 AM daily updates |
| `STOP`    | Pause all alerts |
| `START`   | Resume alerts |
| `SCOUT`   | Step-by-step farm scouting guide |
| `SIGNS`   | Visual pest damage signs to look for |
| `HELP`    | Full command list |

---

## Data Sources

| Source | Data | Cost |
|--------|------|------|
| [Open-Meteo](https://open-meteo.com) | 7-day weather forecast | Free, no key |
| [NASA SMAP](https://nsidc.org/data/smap) | Soil moisture 0–10cm | Free (EarthData account) |
| [SRTM](https://www2.jpl.nasa.gov/srtm/) | Elevation | Free static dataset |

---

## Deployment (Railway)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Deploy
railway login
railway up --service farmsmart
```

Set these environment variables in Railway:
- `WHATSAPP_TOKEN`
- `PHONE_NUMBER_ID`
- `VERIFY_TOKEN`
- `DATABASE_URL`

---

## Cost

| Service | Free Tier | Monthly Cost |
|---------|-----------|-------------|
| Backend (Railway/Render) | 500hr/month | ₦0 |
| Database (Supabase) | 500MB | ₦0 |
| WhatsApp (Meta Cloud API) | 1,000 conversations | ₦0 |
| Weather (Open-Meteo) | Unlimited | ₦0 |
| Soil (NASA EarthData) | Unlimited | ₦0 |
| **SMS fallback** | Pay per use | ~₦4–₦8/SMS |
| **Total** | | **₦0/month** |

---

*FarmSmart — Precision Agriculture for Nigeria · June 2026*
