import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.database import get_db
from app.middleware.auth import verify_token

class MockDBConn:
    def __init__(self):
        self.data = {
            "users": [],
            "profiles": [],
            "history": [],
        }

    async def fetchrow(self, query, *args):
        if "FROM users" in query:
            if len(args) == 1:
                user = next((u for u in self.data["users"] if u["id"] == args[0]), None)
                return user
        elif "FROM health_profiles" in query:
            profile = next((p for p in self.data["profiles"] if p["user_id"] == args[0]), None)
            return profile
        elif "INSERT INTO health_profiles" in query or "UPDATE health_profiles" in query:
            import datetime
            now = datetime.datetime.now()
            profile = {"user_id": args[0], "age": args[1], "sex": args[2], "weight_kg": args[3], "height_cm": args[4], "goal": args[5], "diseases": args[6], "allergies": args[7], "diet_type": args[8], "updated_at": now, "created_at": now}
            existing = next((p for p in self.data["profiles"] if p["user_id"] == args[0]), None)
            if existing:
                self.data["profiles"].remove(existing)
            self.data["profiles"].append(profile)
            return profile
        return None

    async def fetch(self, query, *args):
        if "FROM conversations" in query:
            return self.data["history"]
        return []

    async def execute(self, query, *args):
        if "UPDATE users" in query:
            for u in self.data["users"]:
                if u["id"] == args[1]:
                    u["name"] = args[0]
            return "UPDATE 1"
        elif "INSERT INTO health_profiles" in query or "UPDATE health_profiles" in query:
            # Upsert logic simplified
            profile = {"user_id": args[0], "age": args[1], "gender": args[2], "activity_level": args[3], "dietary_preferences": args[4], "allergies": args[5], "health_goals": args[6], "medical_conditions": args[7]}
            existing = next((p for p in self.data["profiles"] if p["user_id"] == args[0]), None)
            if existing:
                self.data["profiles"].remove(existing)
            self.data["profiles"].append(profile)
            return "INSERT 1"
        elif "INSERT INTO conversations" in query:
            return "INSERT 1"
        return "OK"

@pytest.fixture
def mock_db():
    return MockDBConn()

@pytest.fixture
def override_get_db(mock_db):
    async def _override():
        yield mock_db
    def _override_token():
        return {"user_id": "test_user_id", "email": "test@example.com"}
        
    app.dependency_overrides[get_db] = _override
    app.dependency_overrides[verify_token] = _override_token
    yield mock_db
    app.dependency_overrides.clear()

@pytest_asyncio.fixture
async def async_client(override_get_db):
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client
