from fastapi import APIRouter, Depends, HTTPException, status
from app.models.schemas import ConversationSummary, ConversationDetail, ChatMessage, MessageRole
from app.middleware.auth import verify_token
from app.database import get_db

router = APIRouter()


@router.get("/", response_model=list[ConversationSummary])
async def list_conversations(
    limit: int = 20,
    offset: int = 0,
    current_user: dict = Depends(verify_token),
    conn=Depends(get_db),
):
    rows = await conn.fetch(
        """
        SELECT
            c.id AS session_id,
            c.title,
            c.created_at,
            COUNT(m.id) AS message_count,
            MAX(m.created_at) AS last_message_at
        FROM conversations c
        LEFT JOIN messages m ON m.session_id = c.id
        WHERE c.user_id = $1
        GROUP BY c.id, c.title, c.created_at
        ORDER BY MAX(m.created_at) DESC NULLS LAST
        LIMIT $2 OFFSET $3
        """,
        current_user["user_id"], limit, offset,
    )
    return [
        ConversationSummary(
            session_id=str(r["session_id"]),
            title=r["title"],
            created_at=r["created_at"],
            message_count=r["message_count"],
            last_message_at=r["last_message_at"] or r["created_at"],
        )
        for r in rows
    ]


@router.get("/{session_id}", response_model=ConversationDetail)
async def get_conversation(
    session_id: str,
    current_user: dict = Depends(verify_token),
    conn=Depends(get_db),
):
    conv = await conn.fetchrow(
        "SELECT id, title FROM conversations WHERE id = $1 AND user_id = $2",
        session_id, current_user["user_id"],
    )
    if not conv:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Conversation not found.")

    rows = await conn.fetch(
        "SELECT role, content, image_url, created_at FROM messages WHERE session_id = $1 ORDER BY created_at ASC",
        session_id,
    )
    messages = [
        ChatMessage(
            role=MessageRole(r["role"]),
            content=r["content"],
            image_url=r["image_url"],
            timestamp=r["created_at"],
        )
        for r in rows
    ]
    return ConversationDetail(session_id=session_id, title=conv["title"], messages=messages)


@router.delete("/{session_id}", status_code=204)
async def delete_conversation(
    session_id: str,
    current_user: dict = Depends(verify_token),
    conn=Depends(get_db),
):
    result = await conn.execute(
        "DELETE FROM conversations WHERE id = $1 AND user_id = $2",
        session_id, current_user["user_id"],
    )
    if result == "DELETE 0":
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Conversation not found.")
