import pytest
from unittest.mock import patch, AsyncMock

@pytest.mark.asyncio
async def test_chat_new_session(async_client, mock_db):
    mock_db.data["users"].append({"id": "test_user_id", "email": "test@example.com", "name": "Test User", "plan": "free"})
    
    with patch("app.routers.chat.analyze_nutrition", new_callable=AsyncMock) as mock_analyze:
        mock_analyze.return_value = "This is a mock AI response about nutrition."
        
        response = await async_client.post(
            "/api/v1/chat/",
            json={"message": "What is in an apple?"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["reply"] == "This is a mock AI response about nutrition."
        assert "session_id" in data
        assert data["session_title"] == "What is in an apple?"
