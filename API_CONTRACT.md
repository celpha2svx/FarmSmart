# FarmSmart API Contract

> Single source of truth for the HTTP boundary between the Flutter app and the FastAPI backend.
> Both sides MUST conform. Any change here is a coordinated change in `farmsmart_app/lib/` and `app_api.py`.

**Base URL (production):** `https://farmsmart-dlou.onrender.com`
**Base URL (dev):** `http://localhost:8000`
**All paths are prefixed with `/api`.** No exceptions.

## Conventions

### Response envelope (every endpoint)

```json
{
  "status": "ok" | "error",
  "data":   <endpoint-specific> | null,
  "error":  { "code": "...", "message": "..." } | null
}
```

- `data` is the successful payload. It is `null` on error.
- `error` is `null` on success.
- HTTP status code reflects the truth: 2xx on success, 4xx for client errors, 5xx for server errors.
- Validation errors use HTTP 422 with FastAPI's default shape; clients should treat that as an `error` envelope.

### Auth

- After `/api/auth/verify-otp` succeeds, the client receives `{status, data: {phone, token}}` and stores `token` in `FlutterSecureStorage` under the key `auth_token`.
- All authenticated requests send `Authorization: Bearer <token>` (set automatically by `api_client.dart` interceptor).
- Authenticated endpoints return HTTP 401 with `{status: "error", error: {code: "unauthorized", ...}}` on bad/missing token.

### Error codes (canonical strings)

| code | HTTP | meaning |
|---|---|---|
| `unauthorized` | 401 | bad/missing/expired token |
| `not_found` | 404 | resource missing (e.g. no farm registered for phone) |
| `validation_error` | 422 | request body failed validation |
| `rate_limited` | 429 | too many requests |
| `upstream_unavailable` | 502 | external API (Open-Meteo, WaPOR, HF) failed and we have no fallback |
| `internal_error` | 500 | unexpected server error |

### Dates & times

- All timestamps in responses are ISO 8601 UTC strings, e.g. `"2026-06-30T14:23:11Z"`.
- Calendar dates are `YYYY-MM-DD` in the user's local timezone (not threaded in the API yet; client converts).

### Currency & units

- Prices are NGN (₦). All prices in responses are integers (kobo not used; we accept the rounding).
- Bag = 100 kg (standard for Nigerian grain markets).
- Soil moisture is volumetric % (0–100). NDVI is dimensionless (0–1).

---

## Endpoints

### 1. `POST /api/auth/send-otp`

Request a one-time code for a phone number.

**Request body**
```json
{ "phone": "+2348012345678" }
```

**Response 200**
```json
{
  "status": "ok",
  "data": { "message": "OTP sent" },
  "error": null
}
```

**Response 200 (dev mode only — `APP_ENV=development`)**
```json
{
  "status": "ok",
  "data": { "message": "OTP sent (dev mode)", "dev_code": "482913" },
  "error": null
}
```
The `dev_code` field is present ONLY in development. Production responses never include it. The Flutter UI must read it conditionally.

**Errors**
- `validation_error` 422 — phone missing or malformed.

---

### 2. `POST /api/auth/verify-otp`

Exchange phone + code for a session token.

**Request body**
```json
{ "phone": "+2348012345678", "code": "482913" }
```

**Response 200**
```json
{
  "status": "ok",
  "data": {
    "phone": "+2348012345678",
    "token": "9f4b1c...",
    "is_new_user": true
  },
  "error": null
}
```

**Errors**
- `unauthorized` 401 — invalid or expired code. (`{code: "invalid_otp", message: "Invalid or expired OTP"}`.)
- `validation_error` 422.

---

### 3. `POST /api/farm/register`

Register a farm after onboarding. **Auth required.**

**Request body**
```json
{
  "phone": "+2348012345678",
  "crops": ["maize", "rice"],          // list of crops (lowercase, snake_case)
  "location_raw": "Ibadan, Oyo",       // free text
  "lat": 7.3775,                        // optional in request, but required for advisory
  "lon": 3.9470,                        // optional in request, but required for advisory
  "farm_size": "medium",                // "small" | "medium" | "large"
  "planting_date": "2026-05-12"         // ISO date; optional but recommended
}
```

**Response 200**
```json
{
  "status": "ok",
  "data": {
    "farm": {
      "id": "uuid",
      "phone": "+2348012345678",
      "crops": ["maize", "rice"],
      "primary_crop": "maize",            // server picks the first
      "location_raw": "Ibadan, Oyo",
      "lat": 7.3775,
      "lon": 3.9470,
      "farm_size": "medium",
      "planting_date": "2026-05-12",
      "subscribed": true,
      "registered": "2026-06-30T14:23:11Z"
    }
  },
  "error": null
}
```

> **Note vs old contract:** the old backend expected a single `crop: string`; we now accept `crops: list[str]`. The server stores the first as `primary_crop` and the list as-is. This unblocks multi-crop support without a second registration.

**Errors**
- `unauthorized` 401.
- `validation_error` 422 — `farm_size` not in {small, medium, large}; lat/lon out of range.

---

### 4. `GET /api/farm/{phone}`

Fetch the registered farm for a phone. **Auth optional but recommended.**

**Response 200**
```json
{
  "status": "ok",
  "data": {
    "farm": { /* same shape as register response */ }
  },
  "error": null
}
```

**Response 404**
```json
{
  "status": "error",
  "data": null,
  "error": { "code": "not_found", "message": "Farm not registered yet" }
}
```

---

### 5. `POST /api/advisory/generate`

Generate today's personalized advisory. **Auth required.**

The client is expected to fetch the farm first (or have it cached) and pass the fields.

**Request body**
```json
{
  "phone": "+2348012345678",
  "crop": "maize",
  "lat": 7.3775,
  "lon": 3.9470,
  "planting_date": "2026-05-12"          // optional, server defaults to 30 days ago
}
```

**Response 200**
```json
{
  "status": "ok",
  "data": {
    "advisory": {
      "id": "uuid",
      "crop": "maize",
      "crop_name": "Maize",
      "emoji": "🌽",
      "season": "rainy",
      "region": "southern_guinea_savanna",
      "growth_stage": "vegetative",
      "title": "Maize: Vegetative stage — watch for fall armyworm",
      "message": "Your maize is in the vegetative stage. Soil moisture is adequate. Monitor for armyworm damage on whorls.",
      "risk_level": "medium",            // "low" | "medium" | "high"
      "actions": [                        // flat list, what the home card shows as bullets
        "Scout for fall armyworm on 5 plants per corner",
        "Apply NPK 15-15-15 if not done in the last 21 days"
      ],
      "warnings": [
        "Heavy rain expected in 48h — postpone fertilizer"
      ],
      "weather": {                        // included so home can show real stats
        "temp_max_c": 31.2,
        "temp_min_c": 23.1,
        "humidity_pct": 78,
        "rainfall_mm_24h": 4.2,
        "condition": "cloudy"
      },
      "soil": {
        "moisture_pct": 28.4,
        "temperature_c": 26.1
      },
      "ndvi": 0.62,
      "generated_at": "2026-06-30T06:00:00Z"
    }
  },
  "error": null
}
```

> **Note vs old contract:** the old Flutter code expected `actions: List<String]` only. The new contract adds `warnings` and **bakes weather/soil stats into the advisory response** so the home screen can read them without a second API call. This kills the `'--'` placeholders.

**Errors**
- `unauthorized` 401.
- `validation_error` 422.
- `upstream_unavailable` 502 — only if we genuinely cannot produce an advisory; we should still try to return one with caveats (NDVI=null, soil=null) before falling back to this.

---

### 6. `GET /api/market/prices`

Market prices for a crop across Nigerian markets.

**Query params**
- `crop` (string, required) — e.g. `maize`, `rice`, `beans`, `millet`, `groundnut`, `sorghum`, `soybean`, `cassava`, `yam`, `tomato`, `pepper`.
- `days` (int, default 7) — historical window for the trend chart.

**Response 200**
```json
{
  "status": "ok",
  "data": {
    "crop": "maize",
    "as_of": "2026-06-30T08:00:00Z",
    "current_price_ngn": 245000,          // per bag
    "change_pct_24h": 1.4,
    "weekly_prices_ngn": [238000, 240000, 241500, 243000, 244000, 244500, 245000],
    "markets": [
      {
        "name": "Ibadan",
        "price_ngn": 245000,
        "per_kg_ngn": 2450,
        "distance_km": 12.4,              // computed client-side from farm lat/lon if available; server may return null
        "updated_ago": "2h"
      },
      { "name": "Lagos",   "price_ngn": 250000, "per_kg_ngn": 2500, "distance_km": 120.0, "updated_ago": "4h" },
      { "name": "Kano",    "price_ngn": 230000, "per_kg_ngn": 2300, "distance_km": 730.0, "updated_ago": "6h" }
    ]
  },
  "error": null
}
```

> **Note vs old contract:** the old Flutter code expected `data.current_price`, `data.markets[].price_per_bag`, `data.markets[].updated_ago`. The new contract renames to `current_price_ngn` / `price_ngn` to be explicit about currency. The server now also returns `per_kg_ngn` and an attempt at `distance_km`. `updated_ago` is a human-readable relative string.

> **Server change:** the previous `latest_price` field is folded into `current_price_ngn`. The previous `prices` array (raw rows) is hidden from the client; we expose only what the UI needs.

---

### 7. `GET /api/tasks`

Per-day tasks for a given crop and date. **Auth required.**

**Query params**
- `crop` (string, required)
- `date` (string, required) — `YYYY-MM-DD` in the user's local timezone.
- `lat` (float, optional) — used to pick region
- `lon` (float, optional)
- `planting_date` (string, optional) — used to compute `days_since_planting`. If absent, server assumes 30.

**Response 200**
```json
{
  "status": "ok",
  "data": {
    "date": "2026-06-30",
    "crop": "maize",
    "tasks": [
      {
        "id": "uuid",
        "title": "Apply urea (top-dress)",
        "type": "fertilizer",              // fertilizer | pest | water | harvest | other
        "note": "Apply 4 bags/acre on moist soil, before rain.",
        "due_date": "2026-06-30",
        "completed": false,
        "template_id": "maize-urea-30",    // server-side template id
        "custom": false
      }
    ]
  },
  "error": null
}
```

> **Note vs old contract:** the old endpoint returned templates with `days_after_planting` and no `completed` / `date` fields. The new endpoint returns **per-day instances** (server expands templates to the requested date) with `completed` state. This is the contract the Flutter calendar actually needs.

> **Server change:** the previous `/api/tasks` (GET, templates) becomes `/api/task-templates` (internal/admin only). The Flutter app calls the new per-day `/api/tasks`.

---

### 8. `POST /api/tasks/sync`

Persist task state changes (check / uncheck / edit). **Auth required.**

**Request body**
```json
{
  "phone": "+2348012345678",
  "task_id": "uuid",
  "completed": true,
  "custom_title": null,                   // optional, if user edited the title
  "custom_note": null,                    // optional, if user edited the note
  "due_date": "2026-06-30"
}
```

**Response 200**
```json
{ "status": "ok", "data": { "task_id": "uuid", "completed": true }, "error": null }
```

> **Server change:** this used to write to `AnalyticsEvent` (a comment in the code admitted it). The new contract requires a real `TaskState` table; the storage is moved out of analytics in Phase 3.

---

### 9. `POST /api/pest/detect`

Multipart image upload, returns pest diagnosis. **Auth required.**

**Request (multipart/form-data)**
- `phone` (text)
- `image` (file, max 10 MB, jpg/png)

**Response 200**
```json
{
  "status": "ok",
  "data": {
    "pest_id": "fall_armyworm",
    "pest_name": "Fall Armyworm",
    "scientific_name": "Spodoptera frugiperda",
    "confidence": 0.87,
    "severity": "medium",                 // "low" | "medium" | "high" | "unknown"
    "treatment": "Apply emamectin benzoate 5% WG at 200g/ha. Spray early morning or late evening.",
    "prevention": "Scout weekly. Use pheromone traps. Rotate with non-host crops.",
    "is_simulated": false,                // explicit honesty flag
    "model_version": "hf:pierreguillou/nlp-v2.0-classifier-plant-disease@2024-09"
  },
  "error": null
}
```

**Response 200 (no real model available — degraded mode)**
```json
{
  "status": "ok",
  "data": {
    "pest_id": "unknown",
    "pest_name": "Unable to identify",
    "confidence": 0.0,
    "severity": "unknown",
    "treatment": "Pest detection is currently unavailable. Please contact your local extension officer.",
    "prevention": null,
    "is_simulated": false,                // explicit: NOT simulated. We do not lie.
    "model_version": null
  },
  "error": null
}
```

> **Server change (Phase 1b):** the old `_simulate_detection()` returned a *random pest* with random 72–96% confidence. That is removed. When no model is available, we return an explicit "unable to identify" response with `severity: "unknown"`. The Flutter UI is required to render this honestly.

**Errors**
- `unauthorized` 401.
- `validation_error` 422 — image missing.
- 400 — image > 10 MB.

---

### 10. `GET /api/satellite`

Satellite-derived agricultural data for a coordinate. **No auth.**

**Query params**
- `lat` (float, required)
- `lon` (float, required)

**Response 200**
```json
{
  "status": "ok",
  "data": {
    "lat": 7.3775,
    "lon": 3.9470,
    "date": "2026-06-29",
    "ndvi": 0.62,
    "evapotranspiration_mm": 4.1,
    "drought_index": 2.1,                 // 0 = no drought, 5 = severe
    "soil_moisture_pct": 28.4,
    "cached": true
  },
  "error": null
}
```

> **Server change:** the old fallback returned a hardcoded `0.45` NDVI and `5.0` drought_index when external APIs failed. The new contract returns `null` for any field we couldn't compute, and `upstream_unavailable` (502) only if the whole call is dead. The Flutter home screen reads weather/soil from the `/api/advisory/generate` response, not from here.

---

### 11. `GET /api/announcements`

Active announcements / alerts. **Auth optional.**

**Response 200**
```json
{
  "status": "ok",
  "data": {
    "announcements": [
      {
        "id": "uuid",
        "title": "Fall armyworm outbreak in Oyo",
        "body": "Reports of FAW in Ibadan area. Scout fields.",
        "level": "high",                   // "info" | "warning" | "high"
        "created_at": "2026-06-28T09:00:00Z"
      }
    ]
  },
  "error": null
}
```

> **Flutter change:** the old `announcementsProvider` returned `[]` immediately. The new contract is what it should actually call.

---

### 12. `POST /api/feedback`

Submit feedback. **Auth required.**

**Request body**
```json
{
  "phone": "+2348012345678",
  "message": "The scanner didn't work on my Tecno phone",
  "category": "bug"                      // "bug" | "feature" | "praise" | "other"
}
```

**Response 200**
```json
{
  "status": "ok",
  "data": {
    "feedback_id": "uuid",
    "github_issue_url": "https://github.com/celpha2svx/FarmSmart/issues/42",
    "message": "Thank you! Your feedback helps improve FarmSmart."
  },
  "error": null
}
```

> **Flutter change:** the old `feedback_screen.dart` posted directly to the Cloudflare Worker. The new contract routes through the backend, which forwards to the worker. This gives us persistence, rate limiting, and the option to fail loudly (Phase 6).

---

### 13. `GET /api/version/latest`

Latest app version (for in-app update). **No auth.**

**Response 200**
```json
{
  "status": "ok",
  "data": {
    "version_name": "1.2.0",
    "version_code": 12,
    "apk_url": "https://github.com/.../app-release.apk",
    "changelog": "Bug fixes, new market screen",
    "mandatory": false
  },
  "error": null
}
```

> **Flutter change:** the old OTA flow hit `api.github.com/repos/.../releases/latest` directly. The new contract hits our backend, which can decide whether to push a release (we have admin tooling). Phase 1 keeps both paths working; Phase 7 deprecates the GitHub-direct path.

---

### 14. `POST /api/version/release`

Admin: register a new release. **Bearer `ADMIN_TOKEN` only.** Not used by the app.

---

### 15. `POST /api/analytics/event` & `POST /api/analytics/batch`

Auth required. Reserved for Phase 8+.

---

### 16. `GET /api/weather`

Current weather snapshot for a coordinate from Open-Meteo (no key required).

**Query params**
- `lat` (float, required)
- `lon` (float, required)

**Response 200**
```json
{
  "status": "ok",
  "data": {
    "temperature_c": 28.4,
    "humidity_pct": 78.0,
    "precipitation_mm": 0.0,
    "wind_speed_kmh": 7.2,
    "time": "2026-06-30T14:00",
    "source": "open-meteo"
  },
  "error": null
}
```

On upstream failure fields are `null` and `upstream_error: true`. Status is still `ok` — the caller decides whether to display stale data or hide the row.

---

## Change log

| Date | Change | Reason |
|---|---|---|
| 2026-06-30 | Initial contract | Phase 0 — agreed between Flutter and FastAPI |
