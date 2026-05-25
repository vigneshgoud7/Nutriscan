import httpx
import logging
from fastapi import APIRouter, HTTPException, status, Depends
from app.models.schemas import SignUpRequest, SignInRequest, TokenResponse, SocialAuthRequest
from app.database import get_db
from app.config import settings

router = APIRouter()
logger = logging.getLogger(__name__)

SUPABASE_AUTH_URL = f"{settings.SUPABASE_URL}/auth/v1"
SUPABASE_HEADERS = {
    "apikey": settings.SUPABASE_SERVICE_ROLE_KEY,
    "Content-Type": "application/json",
}


def _supabase_error_detail(response: httpx.Response, fallback: str) -> str:
    try:
        data = response.json()
    except ValueError:
        return fallback

    raw_detail = (
        data.get("message")
        or data.get("error_description")
        or data.get("msg")
        or data.get("error")
        or fallback
    )
    detail = str(raw_detail)
    normalized = detail.lower()

    if "email rate limit exceeded" in normalized or "rate limit" in normalized:
        return "Email rate limit exceeded. Wait a few minutes before trying again, or disable email confirmations while testing."
    if "invalid login credentials" in normalized:
        return "Invalid email or password. If you just signed up, confirm your email first."
    if "already registered" in normalized or "user already registered" in normalized:
        return "That email is already registered. Sign in instead."

    return detail


async def _get_or_create_user_record(conn, user_id: str, email: str, name: str) -> dict:
    row = await conn.fetchrow("SELECT * FROM users WHERE id = $1", user_id)
    if not row:
        row = await conn.fetchrow(
            "INSERT INTO users (id, email, name, plan) VALUES ($1, $2, $3, 'free') RETURNING *",
            user_id, email, name,
        )
    return dict(row)


@router.post("/signup", response_model=TokenResponse)
async def signup(req: SignUpRequest, conn=Depends(get_db)):
    async with httpx.AsyncClient() as client:
        r = await client.post(
            f"{SUPABASE_AUTH_URL}/signup",
            headers=SUPABASE_HEADERS,
            json={
                "email": req.email,
                "password": req.password,
                "data": {"name": req.name, "full_name": req.name}
            },
        )
    if r.status_code not in (200, 201):
        detail = _supabase_error_detail(r, "Sign-up failed.")
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)

    data = r.json()
    user_data = data.get("user")
    if not user_data and "id" in data:
        user_data = data
        
    if not user_data or "id" not in user_data:
        logger.error(f"Unexpected Supabase signup response: {data}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Sign-up failed. The email might already be registered."
        )

    user_id = user_data["id"]
    access_token = data.get("access_token", "")
    
    if not access_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Sign-up successful! Please check your email to confirm your account before signing in."
        )

    user = await _get_or_create_user_record(conn, user_id, req.email, req.name)
    # Update name in DB
    await conn.execute("UPDATE users SET name = $1 WHERE id = $2", req.name, user_id)

    return TokenResponse(
        access_token=access_token,
        user_id=user_id,
        name=req.name,
        plan=user["plan"],
    )


@router.post("/signin", response_model=TokenResponse)
async def signin(req: SignInRequest, conn=Depends(get_db)):
    async with httpx.AsyncClient() as client:
        r = await client.post(
            f"{SUPABASE_AUTH_URL}/token?grant_type=password",
            headers=SUPABASE_HEADERS,
            json={"email": req.email, "password": req.password},
        )
    if r.status_code != 200:
        detail = _supabase_error_detail(r, "Invalid credentials.")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=detail)

    data = r.json()
    user_data = data.get("user")
    if not user_data and "id" in data:
        user_data = data
        
    if not user_data or "id" not in user_data:
        logger.error(f"Unexpected Supabase signup response: {data}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Sign-up failed. The email might already be registered."
        )

    user_id = user_data["id"]
    access_token = data.get("access_token", "")
    user = await _get_or_create_user_record(conn, user_id, req.email, user_data.get("email", ""))

    return TokenResponse(
        access_token=access_token,
        user_id=user_id,
        name=user["name"],
        plan=user["plan"],
    )


@router.post("/social", response_model=TokenResponse)
async def social_auth(req: SocialAuthRequest, conn=Depends(get_db)):
    """Exchange a Google/Apple ID token for a Supabase session."""
    async with httpx.AsyncClient() as client:
        r = await client.post(
            f"{SUPABASE_AUTH_URL}/token?grant_type=id_token",
            headers=SUPABASE_HEADERS,
            json={"provider": req.provider, "id_token": req.provider_token},
        )
    if r.status_code != 200:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Social auth failed.")

    data = r.json()
    user_id = data["user"]["id"]
    email = data["user"].get("email", "")
    name = data["user"].get("user_metadata", {}).get("full_name", email.split("@")[0])
    access_token = data["access_token"]
    user = await _get_or_create_user_record(conn, user_id, email, name)

    return TokenResponse(
        access_token=access_token,
        user_id=user_id,
        name=user["name"],
        plan=user["plan"],
    )
