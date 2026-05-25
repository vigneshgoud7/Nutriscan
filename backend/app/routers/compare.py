import uuid
import logging
from fastapi import APIRouter, Depends, HTTPException
from app.models.schemas import CompareRequest, CompareResponse
from app.middleware.auth import verify_token
from app.database import get_db
from app.services.gemini import compare_products
from app.services.rate_limit import check_rate_limit, check_daily_limit

router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/", response_model=CompareResponse)
async def compare(
    req: CompareRequest,
    current_user: dict = Depends(verify_token),
    conn=Depends(get_db),
):
    user_id = current_user["user_id"]
    check_rate_limit(user_id)

    user_row = await conn.fetchrow("SELECT name, plan FROM users WHERE id = $1", user_id)
    name = user_row["name"] if user_row else "User"
    plan = user_row["plan"] if user_row else "free"

    await check_daily_limit(user_id, plan, conn)

    profile_row = await conn.fetchrow("SELECT * FROM health_profiles WHERE user_id = $1", user_id)
    from app.models.schemas import HealthProfileResponse
    profile = HealthProfileResponse(**dict(profile_row)) if profile_row else None

    products = [{"name": p.name, "image_url": p.image_url} for p in req.products]

    try:
        comparison_text, winner = await compare_products(products, profile, name)
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))

    # Save as a special conversation
    session_id = str(uuid.uuid4())
    names_str = " vs ".join(p["name"] for p in products)
    title = f"Compare: {names_str}"[:100]

    await conn.execute(
        "INSERT INTO conversations (id, user_id, title) VALUES ($1, $2, $3)",
        session_id, user_id, title,
    )

    question = f"Compare these products: {names_str}"
    user_msg_id = str(uuid.uuid4())
    ai_msg_id = str(uuid.uuid4())

    await conn.execute(
        """
        INSERT INTO messages (id, session_id, user_id, role, content, image_url)
        VALUES ($1,$2,$3,'user',$4,NULL), ($5,$2,$3,'assistant',$6,NULL)
        """,
        user_msg_id, session_id, user_id, question,
        ai_msg_id, comparison_text,
    )

    return CompareResponse(
        comparison_text=comparison_text,
        winner=winner,
        session_id=session_id,
    )
