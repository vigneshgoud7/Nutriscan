from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from contextlib import asynccontextmanager
import logging

from app.routers import auth, profile, chat, compare, history
from app.database import create_db_pool, close_db_pool
from app.config import settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting NutriScan API...")
    await create_db_pool()
    yield
    await close_db_pool()
    logger.info("NutriScan API shut down.")


app = FastAPI(
    title="NutriScan API",
    version="1.0.0",
    description="AI-powered nutrition analysis and product comparison API",
    lifespan=lifespan,
    docs_url="/docs" if settings.ENV != "production" else None,
    redoc_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_origin_regex=r"^(https?://(localhost|127\.0\.0\.1)(:\d+)?|https://.*\.vercel\.app)$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(profile.router, prefix="/api/v1/profile", tags=["Health Profile"])
app.include_router(chat.router, prefix="/api/v1/chat", tags=["AI Chat"])
app.include_router(compare.router, prefix="/api/v1/compare", tags=["Product Compare"])
app.include_router(history.router, prefix="/api/v1/history", tags=["Conversation History"])


@app.get("/health")
async def health_check():
    return {"status": "ok", "version": "1.0.0"}
