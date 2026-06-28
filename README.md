# 🌱 FarmSmart

**Precision agriculture for Nigerian farmers.** Personalized weather, soil, and pest advisories delivered to your phone. Works offline. 4 languages.

[![Platform](https://img.shields.io/badge/Android-8%2B-4CAF50?logo=android)](https://github.com/celpha2svx/FarmSmart/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.29-02569B?logo=flutter)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## Features

| Feature | Description |
|---------|-------------|
| 📡 **Satellite Insights** | Daily soil moisture, vegetation health, temperature, and drought alerts from Open-Meteo & FAO WaPOR |
| 📷 **AI Pest Detection** | Snap a photo → HuggingFace AI identifies 17 pests/diseases with exact treatment steps |
| 📅 **Smart Calendar** | Personalized planting, fertilizing, irrigating, spraying, and harvesting schedule per crop |
| 💰 **Market Prices** | Live AFEX Exchange prices across Nigerian markets with bar chart trends |
| 🌍 **4 Languages** | English, Hausa, Yoruba, Igbo — every screen and advisory in your language |
| 📴 **Offline-First** | Local Drift database queues actions, auto-syncs when reconnected; advisories cached 14 days |
| 🔄 **OTA Updates** | Check for updates in-app, download & install APK — no Google Play needed |
| 💬 **Feedback** | Send feedback from the app → Cloudflare Worker → GitHub Issue |

## Screenshots

| | | |
|--|--|--|
| ![Home](docs/screenshots/home.png) | ![Calendar](docs/screenshots/calendar.png) | ![Market](docs/screenshots/market.png) |
| ![Scanner](docs/screenshots/scanner.png) | ![Settings](docs/screenshots/settings.png) | ![OTP](docs/screenshots/otp.png) |

## Tech Stack

**Frontend** — Flutter 3.29, Riverpod, Google Fonts, Drift, Dio, fl_chart, table_calendar, shimmer, image_picker, pinput, flutter_secure_storage

**Backend** — Python 3.12, FastAPI, Uvicorn, APScheduler, httpx, BeautifulSoup4, Pillow, Render

**AI** — HuggingFace Inference API (plant disease classification)

**APIs** — AFEX Exchange (market prices), Open-Meteo (weather), FAO WaPOR (NDVI)

**CI/CD** — GitHub Actions (Flutter APK build + GitHub Release), Render auto-deploy

**Infrastructure** — Cloudflare Worker (feedback → GitHub Issues)

## Installation

1. Download the latest APK from the [Releases page](https://github.com/celpha2svx/FarmSmart/releases/latest)
2. Enable "Install from unknown sources" on your Android device
3. Open the APK and install

### Download options

| Variant | Size | Best for |
|---------|------|----------|
| Universal | 93 MB | All devices |
| arm64-v8a | 34 MB | Most modern phones (2015+) |
| armeabi-v7a | 29 MB | Older phones |
| x86_64 | 37 MB | Emulators / tablets |

Minimum Android version: **8.0 (API 26)**

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | API health check |
| `/register_farm` | POST | Register a farm |
| `/advisory` | POST | Generate personalized advisory |
| `/market_prices` | GET | Current market prices |
| `/tasks` | POST | Generate farm tasks |
| `/sync_tasks` | POST | Sync completed tasks |
| `/pest_detect` | POST | Analyze pest image |
| `/satellite` | GET | Satellite weather data |
| `/send_otp` | POST | Send OTP for auth |
| `/verify_otp` | POST | Verify OTP |
| `/check_session` | POST | Check user session |
| `/feedback` | POST | Submit feedback |

## Development

### Prerequisites

- Flutter 3.29+
- Python 3.12+
- Android SDK 36

### Flutter app

```bash
cd farmsmart_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Backend

```bash
pip install -r requirements.txt
cp .env.example .env  # add your keys
uvicorn app_api:app --reload --port 8000
```

### Environment variables

```
DATABASE_URL=postgresql://...
TELEGRAM_TOKEN=...
HUGGINGFACE_TOKEN=hf_...
HUGGINGFACE_MODEL=pierreguillou/nlp-v2.0-classifier-plant-disease
AFEX_API_BASE=https://api.afexexchange.com/...
```

## Architecture

```
lib/
├── core/
│   ├── database/       # Drift local DB (offline queue)
│   ├── l10n/           # i18n (4 languages, 80+ strings each)
│   ├── network/        # Dio API client
│   ├── providers/      # Shared providers
│   ├── sync/           # Offline sync service
│   ├── theme/          # Design tokens (colors, radius, shadows, spacing)
│   └── widgets/        # Shared widgets (shimmer, empty, error, offline, chip, button)
├── features/
│   ├── auth/           # Splash, signup, OTP
│   ├── calendar/       # Task calendar
│   ├── home/           # Advisory feed
│   ├── market/         # Price charts
│   ├── onboarding/     # First-run flow
│   ├── scanner/        # Pest detection camera
│   └── settings/       # OTA updates, feedback, language
├── navigation/         # Bottom nav shell
└── main.dart           # App entry point
```

## License

MIT — see [LICENSE](LICENSE).

---

*Powered by FAO WaPOR · Open-Meteo · AFEX Exchange · HuggingFace · Made in Nigeria 🇳🇬*
