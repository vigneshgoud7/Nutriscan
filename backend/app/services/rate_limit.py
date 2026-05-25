import time
import logging
from collections import defaultdict
from fastapi import HTTPException, status
from app.config import settings

logger = logging.getLogger(__name__)

# In-memory sliding window per user (minute-level)
_minute_counters: dict[str, list[float]] = defaultdict(list)


def check_rate_limit(user_id: str):
    now = time.time()
    window = 60  # 1 minute
    calls = _minute_counters[user_id]
    # Remove timestamps older than 1 minute
    _minute_counters[user_id] = [t for t in calls if now - t < window]
    if len(_minute_counters[user_id]) >= settings.RATE_LIMIT_PER_MINUTE:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Rate limit exceeded. Max {settings.RATE_LIMIT_PER_MINUTE} requests/minute.",
        )
    _minute_counters[user_id].append(now)


async def check_daily_limit(user_id: str, plan: str, conn) -> None:
    """Check DB-backed daily usage limit."""
    limit = settings.PREMIUM_TIER_DAILY_LIMIT if plan == "premium" else settings.FREE_TIER_DAILY_LIMIT
    row = await conn.fetchrow(
        """
        SELECT COUNT(*) as cnt FROM messages
        WHERE user_id = $1
          AND role = 'user'
          AND created_at > NOW() - INTERVAL '24 hours'
        """,
        user_id,
    )
    count = row["cnt"] if row else 0
    if count >= limit:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Daily limit of {limit} messages reached. {'Upgrade to Premium for more.' if plan == 'free' else 'Please try again tomorrow.'}",
        )
