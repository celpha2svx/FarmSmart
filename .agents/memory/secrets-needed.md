---
name: Secrets needed for full production
description: Which env vars/secrets must be set for each feature to work end-to-end
---

## For SMS OTP delivery (Africa's Talking)
- `AT_API_KEY` — Africa's Talking API key
- `AT_USERNAME` — Africa's Talking username (use "sandbox" for testing, real username for production)
- Without these, OTP works in dev mode only (code shown in API response)

## For pest detection AI
- `HUGGINGFACE_TOKEN` — HuggingFace Inference API token (free tier available at huggingface.co)
- Without this, pest detection returns simulated results (`is_simulated: true`)

## For GitHub Actions → backend notification
- `FARMSMART_ADMIN_TOKEN` — must match `ADMIN_TOKEN` env var on the backend
- Set as a GitHub Actions secret named `FARMSMART_ADMIN_TOKEN`
- Used in the `notify_backend` job in `.github/workflows/build.yml`

## For GitHub Actions APK build itself
- `GITHUB_TOKEN` — automatically provided by GitHub Actions, no setup needed
- If signing the APK: add keystore as base64 secret and update the build step
