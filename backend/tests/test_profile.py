import pytest

@pytest.mark.asyncio
async def test_get_profile_not_found(async_client, mock_db):
    response = await async_client.get("/api/v1/profile/me")
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_upsert_profile(async_client, mock_db):
    payload = {
        "age": 30,
        "sex": "male",
        "weight_kg": 75.5,
        "height_cm": 180.0,
        "goal": "Weight Loss",
        "diseases": ["none"],
        "allergies": ["peanuts"],
        "diet_type": "keto"
    }
    response = await async_client.post("/api/v1/profile/me", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["age"] == 30
    assert data["sex"] == "male"
    assert data["weight_kg"] == 75.5
    assert data["goal"] == "Weight Loss"
    
    # Test getting the profile after upsert
    response_get = await async_client.get("/api/v1/profile/me")
    assert response_get.status_code == 200
    assert response_get.json()["age"] == 30
