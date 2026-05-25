import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
from app.main import app

@pytest.fixture
def test_client(override_get_db):
    return TestClient(app)

def test_signup(test_client, mock_db):
    mock_db.data["users"].append({"id": "test_user_id", "email": "test@example.com", "name": "Test User", "plan": "free"})
    
    with patch("app.routers.auth.httpx.AsyncClient.post") as mock_post:
        # FastAPI's async endpoints are handled by TestClient.
        # However, AsyncClient.post inside the endpoint is async, so the mock needs to be async.
        # Let's use an AsyncMock.
        from unittest.mock import AsyncMock
        mock_post_async = AsyncMock()
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "user": {"id": "test_user_id", "email": "test@example.com"},
            "access_token": "fake_token"
        }
        mock_post_async.return_value = mock_response
        
        with patch("app.routers.auth.httpx.AsyncClient.post", new=mock_post_async):
            response = test_client.post(
                "/api/v1/auth/signup",
                json={"email": "test@example.com", "password": "password123", "name": "Test User"}
            )
            
            assert response.status_code == 200
            data = response.json()
            assert data["access_token"] == "fake_token"
            assert data["user_id"] == "test_user_id"
            assert data["name"] == "Test User"

def test_signin(test_client, mock_db):
    mock_db.data["users"].append({"id": "test_user_id", "email": "test@example.com", "name": "Test User", "plan": "free"})

    from unittest.mock import AsyncMock
    mock_post_async = AsyncMock()
    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "user": {"id": "test_user_id", "email": "test@example.com"},
        "access_token": "fake_token"
    }
    mock_post_async.return_value = mock_response
    
    with patch("app.routers.auth.httpx.AsyncClient.post", new=mock_post_async):
        response = test_client.post(
            "/api/v1/auth/signin",
            json={"email": "test@example.com", "password": "password123"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["access_token"] == "fake_token"
        assert data["user_id"] == "test_user_id"
