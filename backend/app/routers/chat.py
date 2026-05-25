import uuid
import logging
from fastapi import APIRouter, Depends, HTTPException
from app.models.schemas import ChatRequest, ChatResponse, ChatMessage, MessageRole, HealthProfileResponse
from app.middleware.auth import verify_token
from app.database import get_db
from app.services.gemini import analyze_nutrition
from app.services.rate_limit import check_rate_limit, check_daily_limit

router = APIRouter()
logger = logging.getLogger(__name__)


async def _fetch_profile(user_id: str, conn) -> tuple[HealthProfileResponse | None, str]:
    profile_row = await conn.fetchrow("SELECT * FROM health_profiles WHERE user_id = $1", user_id)
    user_row = await conn.fetchrow("SELECT name, plan FROM users WHERE id = $1", user_id)
    name = user_row["name"] if user_row else "User"
    plan = user_row["plan"] if user_row else "free"
    profile = HealthProfileResponse(**dict(profile_row)) if profile_row else None
    return profile, name, plan


async def _get_or_create_session(session_id: str | None, user_id: str, conn) -> tuple[str, str]:
    if session_id:
        row = await conn.fetchrow(
            "SELECT id, title FROM conversations WHERE id = $1 AND user_id = $2",
            session_id, user_id,
        )
        if row:
            return str(row["id"]), row["title"]
    # Create new session
    new_id = str(uuid.uuid4())
    title = "New conversation"
    await conn.execute(
        "INSERT INTO conversations (id, user_id, title) VALUES ($1, $2, $3)",
        new_id, user_id, title,
    )
    return new_id, title


async def _fetch_history(session_id: str, conn, limit: int = 10) -> list[ChatMessage]:
    rows = await conn.fetch(
        """
        SELECT role, content, image_url, created_at
        FROM messages
        WHERE session_id = $1
        ORDER BY created_at DESC
        LIMIT $2
        """,
        session_id, limit,
    )
    messages = []
    for row in reversed(rows):
        messages.append(ChatMessage(
            role=MessageRole(row["role"]),
            content=row["content"],
            image_url=row["image_url"],
            timestamp=row["created_at"],
        ))
    return messages


async def _update_session_title(session_id: str, first_message: str, conn):
    title = first_message[:60] + ("..." if len(first_message) > 60 else "")
    await conn.execute(
        "UPDATE conversations SET title = $1 WHERE id = $2", title, session_id
    )
    return title


@router.post("/", response_model=ChatResponse)
async def chat(
    req: ChatRequest,
    current_user: dict = Depends(verify_token),
    conn=Depends(get_db),
):
    user_id = current_user["user_id"]

    # Rate limiting
    check_rate_limit(user_id)
    profile, name, plan = await _fetch_profile(user_id, conn)
    await check_daily_limit(user_id, plan, conn)

    session_id, session_title = await _get_or_create_session(req.session_id, user_id, conn)
    history = await _fetch_history(session_id, conn)

    # Update title on first message
    if not history:
        session_title = await _update_session_title(session_id, req.message, conn)

    # Call Gemini
    try:
        reply = await analyze_nutrition(
            user_question=req.message,
            image_url=req.image_url,
            history=history,
            profile=profile,
            user_name=name,
        )
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))

    # Persist both messages
    user_msg_id = str(uuid.uuid4())
    ai_msg_id = str(uuid.uuid4())

    await conn.execute(
        """
        INSERT INTO messages (id, session_id, user_id, role, content, image_url)
        VALUES ($1,$2,$3,'user',$4,$5), ($6,$2,$3,'assistant',$7,NULL)
        """,
        user_msg_id, session_id, user_id, req.message, req.image_url,
        ai_msg_id, reply,
    )

    return ChatResponse(
        session_id=session_id,
        session_title=session_title,
        reply=reply,
        message_id=ai_msg_id,
    )
