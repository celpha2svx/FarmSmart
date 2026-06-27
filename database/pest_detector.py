"""
FarmSmart Pest Detection — HuggingFace Inference API proxy.

Flutter sends photo → backend calls HuggingFace free inference API
→ returns pest name, confidence, treatment recommendation.

Uses a free plant-disease classification model from HuggingFace.
"""

import base64
import logging
from typing import Optional

import httpx

from utils.config import settings

logger = logging.getLogger(__name__)

# Mapping of HuggingFace model labels → FarmSmart pests
# Default model: pierreguillou/nlp-v2.0-classifier-plant-disease
# Fallback model if token not configured: use a free public one

HF_API_URL = "https://api-inference.huggingface.co/models"

PEST_TREATMENTS = {
    "fall_armyworm": {
        "name": "Fall Armyworm",
        "severity": "high",
        "treatment": "Apply Emamectin Benzoate 1.9% EC at 2ml/L water. Spray in the evening. "
                     "Alternate with Chlorantraniliprole if re-infestation occurs after 7 days.",
        "prevention": "Scout fields weekly. Use neem extract as preventive spray every 2 weeks.",
    },
    "stem_borer": {
        "name": "Stem Borer",
        "severity": "high",
        "treatment": "Apply Carbofuran 3G granules in whorl at 10kg/ha. "
                     "Or spray Lambda-cyhalothrin 2.5% EC at 20ml/15L water.",
        "prevention": "Plant resistant varieties. Destroy crop residues after harvest.",
    },
    "rice_blast": {
        "name": "Rice Blast",
        "severity": "high",
        "treatment": "Apply Tricyclazole 75% WP at 1g/L water. "
                     "Or Carbendazim 50% WP at 2g/L water. Repeat after 14 days.",
        "prevention": "Use resistant varieties. Avoid excessive nitrogen. Ensure good drainage.",
    },
    "cassava_mosaic": {
        "name": "Cassava Mosaic Virus",
        "severity": "high",
        "treatment": "No cure. Remove and burn infected plants immediately. "
                     "Use disease-free cuttings for next planting.",
        "prevention": "Plant certified virus-free stems. Control whitefly vectors with neem spray.",
    },
    "black_pod": {
        "name": "Black Pod Disease",
        "severity": "high",
        "treatment": "Remove and destroy all infected pods. Spray copper-based fungicide "
                     "(e.g. Bordeaux mixture 1%) every 2-3 weeks in wet season.",
        "prevention": "Prune trees for air circulation. Maintain shade levels. Remove mummified pods.",
    },
    "late_blight": {
        "name": "Late Blight",
        "severity": "high",
        "treatment": "Apply Metalaxyl + Mancozeb (Ridomil Gold) at 50g/15L water. "
                     "Spray every 7-10 days. Remove infected plants.",
        "prevention": "Use resistant varieties. Avoid overhead irrigation. Ensure plant spacing.",
    },
    "early_blight": {
        "name": "Early Blight",
        "severity": "medium",
        "treatment": "Apply Mancozeb 80% WP at 50g/15L water. "
                     "Or Chlorothalonil 75% WP at 40g/15L. Repeat every 10-14 days.",
        "prevention": "Mulch around plants. Practice crop rotation. Remove lower infected leaves.",
    },
    "aphids": {
        "name": "Aphids",
        "severity": "medium",
        "treatment": "Spray neem oil (5ml/L water + few drops soap). "
                     "Or Imidacloprid 17.8% SL at 5ml/15L water for severe infestation.",
        "prevention": "Encourage beneficial insects (ladybugs, lacewings). Avoid excess nitrogen.",
    },
    "whitefly": {
        "name": "Whitefly",
        "severity": "medium",
        "treatment": "Apply Imidacloprid 17.8% SL at 5ml/15L water. "
                     "Or yellow sticky traps for monitoring and control.",
        "prevention": "Use reflective mulch. Remove infected leaves. Plant repellent crops (marigold).",
    },
    "thrips": {
        "name": "Thrips",
        "severity": "medium",
        "treatment": "Spray Lambda-cyhalothrin 2.5% EC at 20ml/15L water. "
                     "Or Spinosad 2.5% SC at 30ml/15L. Spray in evening.",
        "prevention": "Remove weeds that host thrips. Use blue sticky traps.",
    },
    "pod_borer": {
        "name": "Pod Borer",
        "severity": "high",
        "treatment": "Apply Cypermethrin 10% EC at 30ml/15L water at flowering stage. "
                     "Repeat after 14 days if infestation continues.",
        "prevention": "Plant early-maturing varieties. Avoid staggered planting.",
    },
    "leaf_spot": {
        "name": "Leaf Spot",
        "severity": "medium",
        "treatment": "Apply Mancozeb 80% WP at 50g/15L water. "
                     "Or Benomyl 50% WP at 1g/L water. Repeat after 14 days.",
        "prevention": "Practice crop rotation. Ensure good air circulation. Remove infected debris.",
    },
    "downy_mildew": {
        "name": "Downy Mildew",
        "severity": "high",
        "treatment": "Apply Metalaxyl 35% WS at 6g/kg seed (seed treatment). "
                     "For foliar: Metalaxyl + Mancozeb at 50g/15L water.",
        "prevention": "Use resistant varieties. Avoid dense planting. Improve drainage.",
    },
    "powdery_mildew": {
        "name": "Powdery Mildew",
        "severity": "medium",
        "treatment": "Apply Sulfur 80% WP at 30g/15L water. "
                     "Or Carbendazim 50% WP at 1g/L water. Spray every 10-14 days.",
        "prevention": "Avoid overhead watering. Ensure plant spacing. Use resistant varieties.",
    },
    "anthracnose": {
        "name": "Anthracnose",
        "severity": "medium",
        "treatment": "Apply Carbendazim 50% WP at 2g/L water. "
                     "Or Mancozeb 80% WP at 50g/15L water. Repeat after 10-14 days.",
        "prevention": "Use disease-free seeds. Crop rotation. Remove infected plant debris.",
    },
    "rust": {
        "name": "Rust",
        "severity": "medium",
        "treatment": "Apply Tebuconazole 25.9% EC at 20ml/15L water. "
                     "Or Mancozeb 80% WP at 50g/15L water.",
        "prevention": "Plant resistant varieties. Remove volunteer plants. Avoid dense canopy.",
    },
    "healthy": {
        "name": "Healthy",
        "severity": "none",
        "treatment": "No treatment needed. Continue regular management practices.",
        "prevention": "Maintain good agronomic practices. Regular scouting every 7 days.",
    },
}


async def detect_pest(image_bytes: bytes) -> dict:
    """
    Send image to HuggingFace Inference API for plant disease classification.
    
    Returns structured result with pest name, confidence, severity, treatment.
    Falls back to simulated result if HF token not configured.
    """
    if not settings.huggingface_token:
        logger.warning("HUGGINGFACE_TOKEN not set — using simulated detection")
        return _simulate_detection()

    model = settings.huggingface_model
    url = f"{HF_API_URL}/{model}"

    encoded = base64.b64encode(image_bytes).decode("utf-8")

    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(
                url,
                headers={"Authorization": f"Bearer {settings.huggingface_token}"},
                json={"inputs": f"data:image/jpeg;base64,{encoded}"},
            )
            if resp.status_code == 200:
                result = resp.json()
                return _parse_hf_result(result)
            elif resp.status_code == 503:
                # Model is loading on HF — return simulated result for first use
                logger.info("HF model loading — returning simulated result")
                return _simulate_detection()
            else:
                logger.warning(f"HF API error {resp.status_code}: {resp.text[:200]}")
                return _simulate_detection()
    except Exception as e:
        logger.warning(f"HF API call failed: {e}")
        return _simulate_detection()


def _parse_hf_result(result: list | dict) -> dict:
    """Parse HuggingFace API response into structured pest detection result."""
    if isinstance(result, list) and len(result) > 0:
        # Most HF image models return: [[{"label": "...", "score": ...}, ...]]
        predictions = result[0] if isinstance(result[0], list) else result
        if predictions and len(predictions) > 0:
            top = predictions[0]
            label = top.get("label", "").lower().replace(" ", "_")
            confidence = round(top.get("score", 0) * 100, 1)
            return _build_pest_result(label, confidence)

    return _simulate_detection()


def _build_pest_result(pest_id: str, confidence: float) -> dict:
    """Build structured result from pest ID."""
    info = PEST_TREATMENTS.get(pest_id, PEST_TREATMENTS["fall_armyworm"])
    return {
        "pest_id": pest_id,
        "pest_name": info["name"],
        "confidence": min(confidence, 99.0),
        "severity": info["severity"],
        "treatment": info["treatment"],
        "prevention": info["prevention"],
        "is_simulated": False,
    }


def _simulate_detection() -> dict:
    """
    Simulated detection when HuggingFace is unavailable.
    Returns realistic-looking result for demo/testing.
    Used only as fallback — real detection comes from HF.
    """
    import random
    pest_ids = list(PEST_TREATMENTS.keys())
    # Exclude healthy for simulation
    pest_ids.remove("healthy")
    pest_id = random.choice(pest_ids)
    info = PEST_TREATMENTS[pest_id]
    confidence = round(random.uniform(72.0, 96.0), 1)
    return {
        "pest_id": pest_id,
        "pest_name": info["name"],
        "confidence": confidence,
        "severity": info["severity"],
        "treatment": info["treatment"],
        "prevention": info["prevention"],
        "is_simulated": True,
    }
