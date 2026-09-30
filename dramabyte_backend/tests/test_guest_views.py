from unittest.mock import AsyncMock
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.api.preview_limits import limit_preview
from app.api.routes.public_views import guest_view_service
from app.application.guest_views import GuestViewService
from app.main import app


@pytest.mark.parametrize(
    "result,expected", [("ok", True), ("duplicate", True), ("unavailable", False)]
)
async def test_guest_views_only_accept_successful_or_duplicate_events(result, expected):
    store = AsyncMock()
    store.record.return_value = result
    assert await GuestViewService(store).record(uuid4(), uuid4()) is expected


def test_guest_view_endpoint_validates_events_and_denies_unavailable_episodes():
    service = AsyncMock()
    service.record.return_value = True
    app.dependency_overrides[guest_view_service] = lambda: service
    app.dependency_overrides[limit_preview] = lambda: None
    try:
        with TestClient(app) as client:
            body = {"episode_id": str(uuid4()), "event_id": str(uuid4())}
            response = client.post("/api/v1/public/views", json=body)
            assert response.status_code == 204
            assert response.headers["cache-control"] == "no-store"
            assert (
                client.post(
                    "/api/v1/public/views",
                    json={"episode_id": "invalid", "event_id": "invalid"},
                ).status_code
                == 422
            )
            service.record.return_value = False
            assert client.post("/api/v1/public/views", json=body).status_code == 404
    finally:
        app.dependency_overrides.clear()
