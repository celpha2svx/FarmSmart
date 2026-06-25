"""
Translation layer: Weather forecast data → farmer-readable WhatsApp message.
Converts meteorological data into harvest/spray/irrigate recommendations.
"""


def translate_weather_forecast(
    daily_forecasts: list[dict],
    location: str = "your farm",
) -> str:
    """
    Convert 3-day weather forecast into an actionable farmer message.

    Args:
        daily_forecasts: List of daily weather dicts from weather.py fetcher
        location:        Farm location name for personalisation

    Returns:
        Formatted WhatsApp message string
    """
    if not daily_forecasts:
        return "⚠️ Weather data unavailable. Please try again later."

    lines = [
        f"🌱 *FarmSmart*\n",
        f"⛅ *3-Day Weather* for {location}\n",
    ]

    for i, day in enumerate(daily_forecasts[:3]):
        label    = ["Today", "Tomorrow", "Day 3"][i]
        icon     = _weather_icon(day.get("rainfall_mm", 0), day.get("rain_probability", 0))
        temp_max = day.get("temp_max", day.get("temperature_c", 30))
        rain_pct = day.get("rain_probability", 0)

        if rain_pct > 50:
            rain_note = f" ({int(rain_pct)}% rain chance)"
        else:
            rain_note = ""

        lines.append(f"{label:<10}{icon} {temp_max:.0f}°C{rain_note}")

    # ── Farming advice based on the 3-day window ──────────────────────────
    advice = _generate_farming_advice(daily_forecasts[:3])
    lines.append(f"\n🚜 *Farming Advice:*")
    for tip in advice:
        lines.append(f"• {tip}")

    lines.append("\n_Reply DAILY for daily updates_")
    return "\n".join(lines).strip()


def _weather_icon(rainfall_mm: float, rain_prob: float) -> str:
    if rain_prob > 70 or rainfall_mm > 5:
        return "🌧"
    elif rain_prob > 40 or rainfall_mm > 1:
        return "🌦"
    elif rain_prob > 20:
        return "⛅"
    return "☀️"


def _generate_farming_advice(daily_forecasts: list[dict]) -> list[str]:
    """Generate 2–4 actionable farming tips from the 3-day forecast."""
    tips      = []
    today     = daily_forecasts[0] if daily_forecasts else {}
    tomorrow  = daily_forecasts[1] if len(daily_forecasts) > 1 else {}

    today_rain    = today.get("rain_probability", 0)
    tomorrow_rain = tomorrow.get("rain_probability", 0)
    today_mm      = today.get("rainfall_mm", 0)

    if tomorrow_rain > 60:
        tips.append("Delay fertilizer application until after rain passes")
        tips.append("Rain tomorrow — cover stored produce tonight")
    elif today_rain < 20 and tomorrow_rain < 20:
        tips.append("Good day to spray — low rain risk for next 2 days")
        tips.append("Consider irrigation if soil moisture is low")

    if today_rain < 30 and today.get("temp_max", 30) < 36:
        tips.append("Good conditions for harvesting today")

    any_rain = any(
        d.get("rainfall_mm", 0) > 2 for d in daily_forecasts
    )
    if any_rain:
        tips.append("Rain expected — good natural irrigation coming")

    return tips[:4] if tips else ["Continue normal farm activities"]
