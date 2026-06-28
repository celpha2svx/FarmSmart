---
name: Backend endpoint map
description: Canonical API routes and request/response shapes for all Flutter providers
---

## Auth
- POST `/api/auth/send-otp` — `{phone}` → `{status, code (dev only), message}`
- POST `/api/auth/verify-otp` — `{phone, code}` → `{status, phone, token}`

## Farm
- POST `/api/farm/register` — `{phone, token, crop, location_raw, lat, lon, farm_size, name}` → `{status, farm}`
- GET `/api/farm/{phone}?token=` → `{status, farm}`

## Advisory
- POST `/api/advisory/generate` — `{phone, token, crop, days_since_planting, lat, lon}` → `{status, advisory: {title, message, tips[], warnings[], action_items[{text, priority}]}}`

## Announcements
- GET `/api/announcements` → `{status, announcements: [{id, title, body, level}]}`

## Market
- GET `/api/market/prices?crop=maize&days=7` → `{status, crop, prices: [{crop, market, price_ngn, unit, price_date, source}], latest_price}`

## Tasks
- GET `/api/tasks?crop=maize&region=all&season=all` → `{status, crop, tasks: [{id, days_after_planting, task_type, title, description, region, season}]}`
- POST `/api/tasks/sync` — `{phone, token, task_id, done}` → `{status}`

## Scanner
- POST `/api/pest/detect` — multipart: `phone, token, image` → `{status, result: {pest_id, pest_name, confidence, severity, treatment, prevention, is_simulated}}`

## Satellite/Weather
- GET `/api/satellite?lat=&lon=` → `{status, data: {ndvi, evapotranspiration, drought_index, soil_moisture, date, cached}}`
- GET `/api/weather?lat=&lon=` → `{status, temperature, humidity, precipitation, wind_speed, time}` (Open-Meteo, free)

## Analytics
- POST `/api/analytics/event` — `{phone, token, event_type, event_data}` → `{status}`

## OTA
- GET `/api/version/latest` → `{status, version_name, version_code, apk_url, changelog, mandatory}`
- POST `/api/version/release` (admin) — `{version_name, version_code, apk_url, changelog, mandatory}`
