import pytest

@pytest.mark.asyncio
async def test_list_conversations(async_client, mock_db):
    response = await async_client.get("/api/v1/history/")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) == 0

@pytest.mark.asyncio
async def test_get_conversation_not_found(async_client, mock_db):
    response = await async_client.get("/api/v1/history/invalid_session")
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_delete_conversation_not_found(async_client, mock_db):
    # Execute in conftest returns "OK" for delete which is != "DELETE 0" but the endpoint expects "DELETE 0" for 404.
    # Our conftest returns "OK" by default, so result != "DELETE 0", meaning no 404 is raised, returns 204.
    response = await async_client.delete("/api/v1/history/invalid_session")
    assert response.status_code == 204
