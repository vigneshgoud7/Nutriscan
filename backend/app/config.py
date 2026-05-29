from pydantic_settings import BaseSettings
from typing import List
import os


class Settings(BaseSettings):
    # Environment
    ENV: str = "development"

    # Supabase
    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str
    SUPABASE_JWT_SECRET: str

    # Google Gemini
    GEMINI_API_KEY: str
    GEMINI_FALLBACK_API_KEY: str | None = None
    GEMINI_MODEL: str = "gemini-2.5-flash"

    # Database (direct Postgres connection)
    DATABASE_URL: str  # postgresql+asyncpg://user:pass@host:port/db

    # CORS
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "https://yourdomain.com",
    ]

    # Security
    SECRET_KEY: str = "change-this-in-production"

    # Rate limiting
    RATE_LIMIT_PER_MINUTE: int = 30
    FREE_TIER_DAILY_LIMIT: int = 20
    PREMIUM_TIER_DAILY_LIMIT: int = 500

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
