# Changelog

## 100.0.0 — Phase 1 & 2 rewrite
- **API contract:** New `API_CONTRACT.md`; all endpoints on `/api/*` with `{status, data, error}` envelope
- **Auth:** New 4-digit PIN login (`/api/auth/login-pin`, `/api/auth/set-pin`); scrypt-hashed, per-user salt
- **Language picker** is now the first screen the farmer sees (English, Hausa, Yoruba, Igbo, Pidgin)
- **Onboarding rewrite:** 4 steps — multi-crop, type-to-search LGA via offline Nigerian LGA table, farm size, per-crop planting date
- **Home screen:** real weather + soil data from advisory (no more hardcoded `--`); warm advisory tone with warnings + actions
- **Pest scanner:** honest "unable to identify" view when the AI can't recognise a photo — no more random pest simulation
- **Feedback:** routes through `/api/feedback`; surfaces real success/failure instead of always saying "thanks"
- **Tasks:** per-day expansion with real `TaskState` table (replaces the "Phase 2" stub)
- **Market prices:** new contract shape (current_price_ngn, weekly_prices_ngn, markets[]); AFEX-sourced
- **Cleanup:** removed hardcoded phone fallback, removed `_simulate_detection`, removed dead files
- **CI:** new `ci.yml` runs pytest + flutter analyze on every push; `build-apk.yml` builds release on `v*` tags

## 1.0.1
- Fix R8 release build (add proguard rules for tflite_flutter GPU classes)
- Upgrade AGP 8.6.0, Gradle 8.7, compileSdk 35, minSdk 26
- Add complete Android platform directory with mipmap icons
- Fix Drift cascade notation for v2.x compatibility
- Fix import conflicts and type mismatches
- Resolve dependency version conflicts

## 1.0.0
- Initial release
- Farm registration (crop, location, farm size)
- Daily advisory dashboard (weather, soil, pest)
- AI crop scanner (pest/disease detection)
- Farming calendar with daily tasks
- Market prices
- Hausa, Yoruba, Igbo, English support
- Offline-first (advisories cached for 14 days)
- In-app update system
- Feedback & support
