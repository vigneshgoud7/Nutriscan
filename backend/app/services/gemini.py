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

SYSTEM_PROMPT_TEMPLATE = """You are NutriScan AI, a personal nutrition assistant. You analyze food products, nutrition labels, and food images, then give answers specifically tailored to the user's health profile.

## User health profile
Name: {name}
Age: {age} | Sex: {sex} | Weight: {weight_kg} kg | Height: {height_cm} cm
Health goal: {goal}
Medical conditions: {diseases}
Allergies & intolerances: {allergies}
Dietary preference: {diet_type}

## Your rules
1. EXTREMELY IMPORTANT: You MUST first directly answer the user's specific question. Then, conclude with a "**Bottom line for you:**" section consisting of 1-3 highly concise sentences personalized to their health profile.
2. Do NOT describe the visual contents of the image.
3. Do NOT extract or list nutrition facts unless explicitly asked.
4. Do NOT use bullet points or add any other sections besides your answer and the bottom line.
5. ALWAYS personalize the bottom line to the health profile above.
6. If a product contains an allergen from the user's profile, start your bottom line with "⚠️ ALLERGY WARNING:" and then explain why.
7. Never diagnose medical conditions. If symptoms are described, recommend consulting a doctor.
8. If an image is unclear or not a food/label, ask the user to retake it rather than guessing.
9. Respond in English only.
10. EXTREMELY IMPORTANT: If asked about your identity, creator, or underlying technology, you MUST state that you are "NutriScan AI, a proprietary nutrition model." NEVER mention Google, Gemini, OpenAI, or being a large language model."""


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


async def _call_gemini_fallback(parts: list, system_instruction: str) -> str:
    """Fallback to a secondary Gemini API key using REST if the first rate limits."""
    if not settings.GEMINI_FALLBACK_API_KEY:
        raise ValueError("No fallback Gemini API key configured")
        
    api_parts = []
    for p in parts:
        if isinstance(p, str):
            api_parts.append({"text": p})
        elif isinstance(p, dict) and "data" in p:
            api_parts.append({
                "inline_data": {
                    "mime_type": p.get("mime_type", "image/jpeg"),
                    "data": p["data"]
                }
            })
            
    payload = {
        "system_instruction": {
            "parts": [{"text": system_instruction}]
        },
        "contents": [
            {"role": "user", "parts": api_parts}
        ]
    }
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{settings.GEMINI_MODEL}:generateContent?key={settings.GEMINI_FALLBACK_API_KEY}"
    
    async with httpx.AsyncClient(timeout=30) as client:
        r = await client.post(url, json=payload)
        r.raise_for_status()
        data = r.json()
        return data["candidates"][0]["content"]["parts"][0]["text"]




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
        f"## Conversation history\n{history_text}\n\n## Current question\n{user_question}"
    ]

    if image_url:
        img_data = await _download_image_as_base64(image_url)
        if img_data:
            mime, b64 = img_data
            parts.append({"mime_type": mime, "data": b64})
        else:
            parts[0] += "\n\n(Note: the user attached an image but it could not be loaded. Ask them to re-upload.)"

    try:
        model = genai.GenerativeModel(
            model_name=settings.GEMINI_MODEL,
            system_instruction=system_prompt
        )
        response = model.generate_content(parts)
        return response.text
    except Exception as e:
        error_msg = str(e).lower()
        if "429" in error_msg or "quota" in error_msg or "resourceexhausted" in error_msg:
            logger.warning("Gemini primary rate limit hit! Trying fallback key...")
            if settings.GEMINI_FALLBACK_API_KEY:
                try:
                    return await _call_gemini_fallback(parts, system_prompt)
                except Exception as fallback_err:
                    logger.exception(f"Gemini fallback also failed: {fallback_err}")
            raise RuntimeError("Service error.")
                
        logger.exception("Gemini API error")
        if settings.ENV != "production":
            raise RuntimeError(f"Service error: {e}")
        raise RuntimeError("Service error.")


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

    parts = [f"## Comparison request\n{question}"]

    for p in products:
        img_data = await _download_image_as_base64(p["image_url"])
        if img_data:
            mime, b64 = img_data
            parts.append({"mime_type": mime, "data": b64})

    try:
        model = genai.GenerativeModel(
            model_name=settings.GEMINI_MODEL,
            system_instruction=system_prompt
        )
        response = model.generate_content(parts)
        text = response.text
    except Exception as e:
        error_msg = str(e).lower()
        if "429" in error_msg or "quota" in error_msg or "resourceexhausted" in error_msg:
            logger.warning("Gemini primary rate limit hit during comparison! Trying fallback key...")
            if settings.GEMINI_FALLBACK_API_KEY:
                try:
                    text = await _call_gemini_fallback(parts, system_prompt)
                except Exception as fallback_err:
                    logger.exception(f"Gemini fallback also failed: {fallback_err}")
                    raise RuntimeError("Service error.")
            else:
                raise RuntimeError("Service error.")
        else:
            logger.exception("Gemini compare error")
            if settings.ENV != "production":
                raise RuntimeError(f"Service error: {e}")
            raise RuntimeError("Service error.")

    winner = None
    for name in names:
        if name.lower() in text.lower():
            winner = name
            break
    return text, winner

