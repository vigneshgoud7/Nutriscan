import asyncpg
import logging
from app.config import settings

logger = logging.getLogger(__name__)

_pool: asyncpg.Pool | None = None


async def create_db_pool():
    global _pool
    # asyncpg needs the plain postgresql:// URI (not +asyncpg)
    url = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
    _pool = await asyncpg.create_pool(
        url,
        min_size=2,
        max_size=10,
        command_timeout=60,
    )
    logger.info("Database pool created.")


async def close_db_pool():
    global _pool
    if _pool:
        await _pool.close()
        logger.info("Database pool closed.")


async def get_db() -> asyncpg.Connection:
    if _pool is None:
        raise RuntimeError("Database pool not initialised.")
    async with _pool.acquire() as conn:
        yield conn
