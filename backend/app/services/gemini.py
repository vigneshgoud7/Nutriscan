import google.generativeai as genai
import httpx
import base64
import logging
import os
from typing import Optional, List
from app.config import settings
from app.models.schemas import ChatMessage, HealthProfileResponse

logger = logging.getLogger(__name__)


if settings.ENV != "production":
    for proxy_var in ("HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "http_proxy", "https_proxy", "all_proxy"):
        if os.environ.get(proxy_var, "").startswith("http://127.0.0.1:9"):
            os.environ.pop(proxy_var, None)

genai.configure(api_key=settings.GEMINI_API_KEY)
_model = genai.GenerativeModel(settings.GEMINI_MODEL)

SYSTEM_PROMPT_TEMPLATE = """You are NutriScan AI, a personal nutrition assistant. You analyze food products, nutrition labels, and food images, then give answers specifically tailored to the user's health profile.

## User health profile
Name: {name}
Age: {age} | Sex: {sex} | Weight: {weight_kg} kg | Height: {height_cm} cm
Health goal: {goal}
Medical conditions: {diseases}
Allergies & intolerances: {allergies}
Dietary preference: {diet_type}

## Your rules
1. EXTREMELY IMPORTANT: You must ONLY output a "**Bottom line for you:**" section consisting of 1-3 highly concise, personalized sentences.
2. Do NOT describe the visual contents of the image.
3. Do NOT extract or list nutrition facts.
4. Do NOT use bullet points or add any other sections.
5. ALWAYS personalize the bottom line to the health profile above.
6. If a product contains an allergen from the user's profile, start your bottom line with "⚠️ ALLERGY WARNING:" and then explain why.
7. Never diagnose medical conditions. If symptoms are described, recommend consulting a doctor.
8. If an image is unclear or not a food/label, ask the user to retake it rather than guessing.
9. Respond in English only."""


async def _download_image_as_base64(url: str) -> Optional[tuple[str, str]]:
    """Download an image URL and return (mime_type, base64_data)."""
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            r = await client.get(url)
            r.raise_for_status()
            mime = r.headers.get("content-type", "image/jpeg").split(";")[0]
            return mime, base64.b64encode(r.content).decode()
    except Exception as e:
        logger.error(f"Image download failed for {url}: {e}")
        return None


def _build_system_prompt(profile: Optional[HealthProfileResponse], user_name: str) -> str:
    if profile is None:
        return SYSTEM_PROMPT_TEMPLATE.format(
            name=user_name, age="not provided", sex="not provided",
            weight_kg="not provided", height_cm="not provided",
            goal="general healthy eating",
            diseases="none", allergies="none", diet_type="no preference",
        )
    return SYSTEM_PROMPT_TEMPLATE.format(
        name=user_name,
        age=profile.age or "not provided",
        sex=profile.sex or "not provided",
        weight_kg=profile.weight_kg or "not provided",
        height_cm=profile.height_cm or "not provided",
        goal=profile.goal or "general healthy eating",
        diseases=", ".join(profile.diseases) if profile.diseases else "none",
        allergies=", ".join(profile.allergies) if profile.allergies else "none",
        diet_type=profile.diet_type or "no preference",
    )


def _history_to_text(history: List[ChatMessage]) -> str:
    if not history:
        return "No prior conversation."
    lines = []
    for msg in history:
        role = "User" if msg.role == "user" else "NutriScan AI"
        lines.append(f"{role}: {msg.content}")
    return "\n".join(lines)


async def analyze_nutrition(
    user_question: str,
    image_url: Optional[str],
    history: List[ChatMessage],
    profile: Optional[HealthProfileResponse],
    user_name: str,
) -> str:
    system_prompt = _build_system_prompt(profile, user_name)
    history_text = _history_to_text(history)

    parts = [
        f"{system_prompt}\n\n## Conversation history\n{history_text}\n\n## Current question\n{user_question}"
    ]

    if image_url:
        img_data = await _download_image_as_base64(image_url)
        if img_data:
            mime, b64 = img_data
            parts.append({"mime_type": mime, "data": b64})
        else:
            parts[0] += "\n\n(Note: the user attached an image but it could not be loaded. Ask them to re-upload.)"

    try:
        response = _model.generate_content(parts)
        return response.text
    except Exception as e:
        logger.exception("Gemini API error")
        if settings.ENV != "production":
            raise RuntimeError(f"AI service error: {e}")
        raise RuntimeError("AI service temporarily unavailable. Please try again.")


async def compare_products(
    products: list[dict],   # [{"name": str, "image_url": str}]
    profile: Optional[HealthProfileResponse],
    user_name: str,
) -> tuple[str, Optional[str]]:
    system_prompt = _build_system_prompt(profile, user_name)

    names = [p["name"] for p in products]
    question = (
        f"Please compare these {len(products)} products side by side:\n"
        + "\n".join(f"- Product {i+1}: {p['name']}" for i, p in enumerate(products))
        + "\n\nFor each product: extract all nutrition facts from the label image. "
        "Then give a clear side-by-side comparison table. "
        "Finish with a definitive recommendation of which product is best for this specific user and why."
    )

    parts = [f"{system_prompt}\n\n## Comparison request\n{question}"]

    for p in products:
        img_data = await _download_image_as_base64(p["image_url"])
        if img_data:
            mime, b64 = img_data
            parts.append({"mime_type": mime, "data": b64})

    try:
        response = _model.generate_content(parts)
        text = response.text
        winner = None
        for name in names:
            if name.lower() in text.lower():
                winner = name
                break
        return text, winner
    except Exception as e:
        logger.exception("Gemini compare error")
        if settings.ENV != "production":
            raise RuntimeError(f"AI service error: {e}")
        raise RuntimeError("AI service temporarily unavailable. Please try again.")
