# FarmSmart Mobile App

Precision agriculture for Nigerian smallholder farmers.
Offline-first Flutter app powered by FAO satellite data + FarmSmart backend.

## Architecture

```
lib/
├── core/           # Constants, theme, network, database, localization
├── data/           # Remote APIs (FarmSmart + FAO), local SQLite
├── domain/         # Entities, repository interfaces, use cases
├── presentation/   # Riverpod providers, screens, widgets
```

### Key Patterns
- **Offline-first**: SQLite via Drift, syncs when connected
- **Riverpod**: State management and dependency injection
- **Clean Architecture**: Data → Domain → Presentation layers
- **Localization**: English, Hausa, Yoruba, Igbo

## Setup

### Prerequisites
- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0

### Install
```bash
cd farmsmart_app
flutter pub get
```

### Generate code
```bash
# Drift database (requires build_runner)
dart run build_runner build --delete-conflicting-outputs
```

### Run
```bash
flutter run
```

## FAO Data Sources (free, no API key)
- **WaPOR v3**: Evapotranspiration, biomass, water productivity
- **ASIS**: Agricultural Stress Index, drought, vegetation health
- **Digital Earth Africa**: Sentinel-2, CHIRPS rainfall, NDVI

## Backend
FarmSmart FastAPI backend at https://farmsmart-dlou.onrender.com

## Data Flow
```
Satellite (FAO) ──→ Backend API ──→ App (online)
                                       ↕ sync
                                   SQLite (offline)
```
