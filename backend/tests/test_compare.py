import pytest
from unittest.mock import patch, AsyncMock

@pytest.mark.asyncio
async def test_compare_products(async_client, mock_db):
    mock_db.data["users"].append({"id": "test_user_id", "email": "test@example.com", "name": "Test User", "plan": "free"})
    
    with patch("app.routers.compare.compare_products", new_callable=AsyncMock) as mock_compare:
        mock_compare.return_value = ("Product A is better than Product B.", "Product A")
        
        response = await async_client.post(
            "/api/v1/compare/",
            json={"products": [
                {"name": "Product A", "image_url": "url_a"},
                {"name": "Product B", "image_url": "url_b"}
            ]}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["comparison_text"] == "Product A is better than Product B."
        assert data["winner"] == "Product A"
        assert "session_id" in data
