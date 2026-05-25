import asyncio
import httpx
from app.config import settings

SUPABASE_AUTH_URL = f"{settings.SUPABASE_URL}/auth/v1"
SUPABASE_HEADERS = {
    "apikey": settings.SUPABASE_SERVICE_ROLE_KEY,
    "Content-Type": "application/json",
}

async def test():
    async with httpx.AsyncClient() as client:
        # Try format 1
        r1 = await client.post(
            f"{SUPABASE_AUTH_URL}/signup",
            headers=SUPABASE_HEADERS,
            json={
                "email": "test111@example.com",
                "password": "password",
                "data": {"name": "Test User"}
            },
        )
        print("Format 1 (data at root):", r1.status_code, r1.text)

        # Try format 2
        r2 = await client.post(
            f"{SUPABASE_AUTH_URL}/signup",
            headers=SUPABASE_HEADERS,
            json={
                "email": "test222@example.com",
                "password": "password",
                "options": {
                    "data": {"name": "Test User"}
                }
            },
        )
        print("Format 2 (data in options):", r2.status_code, r2.text)

if __name__ == "__main__":
    asyncio.run(test())
