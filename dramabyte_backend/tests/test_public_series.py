from unittest.mock import AsyncMock, patch
from uuid import uuid4

import pytest
from fastapi import HTTPException
from redis.exceptions import ConnectionError as RedisConnectionError
from starlette.requests import Request

from app.api.preview_limits import limit_preview
from app.application.public_series import PublicSeriesService
from app.domain.series import SeriesError

SERIES = uuid4()
IDS = [str(uuid4()) for _ in range(4)]


class Store:
    async def details(self, series_id):
        return {
            "series_id": str(SERIES),
            "title": "Story",
            "free_episode_count": None,
            "episodes": [
                {"episode_id": id, "episode_number": i + 1} for i, id in enumerate(IDS)
            ],
        }

    async def playlist(self, series_id):
        raise AssertionError("Authenticated playlist must not be used")

    async def public_playlist(self, series_id):
        return [
            {
                "series_id": str(SERIES),
                "episode_id": id,
                "episode_number": i + 1,
                "series_title": "Story",
                "series_description": "",
                "genre": "Drama",
                "series_thumbnail": "",
                "episode_thumbnail": "",
                "episode_description": "",
                "duration_seconds": 60,
                "aspect_ratio": "9:16",
                "video_key": f"videos/{i + 1}.mp4",
                "published_count": 4,
                "likes": 0,
            }
            for i, id in enumerate(IDS)
        ]


async def test_guests_only_receive_first_two_published_episode_links():
    signed = []

    def sign(key, revision=None):
        signed.append(key)
        return f"https://storage/{key}?expires=300"

    service = PublicSeriesService(Store(), sign)
    details = await service.details(SERIES)
    assert [item.locked for item in details.episodes] == [False, False, True, True]
    result = await service.playlist(SERIES)
    assert [item.episode_number for item in result] == [1, 2]
    assert signed == ["videos/1.mp4", "videos/2.mp4"]


async def test_mismatched_series_and_forged_episode_numbers_are_never_signed():
    store = Store()
    rows = await store.public_playlist(SERIES)
    rows[0]["series_id"] = str(uuid4())
    rows[1]["episode_number"] = 1
    rows[2]["episode_number"] = 1
    store.public_playlist = AsyncMock(return_value=rows)
    signer = AsyncMock()
    assert await PublicSeriesService(store, signer).playlist(SERIES) == []
    signer.assert_not_called()


async def test_unpublished_or_missing_series_cannot_issue_links():
    store = Store()
    store.details = AsyncMock(return_value=None)
    store.public_playlist = AsyncMock()
    with pytest.raises(SeriesError):
        await PublicSeriesService(store, lambda key: key).playlist(SERIES)
    store.public_playlist.assert_not_called()


@pytest.mark.parametrize("count,status", [(121, 429), (120, None)])
async def test_anonymous_preview_rate_limit(count, status):
    request = Request({"type": "http", "client": ("127.0.0.1", 5000)})
    redis = AsyncMock()
    redis.__aenter__.return_value = redis
    redis.eval.return_value = count
    with patch("app.api.preview_limits.Redis.from_url", return_value=redis):
        if status:
            with pytest.raises(HTTPException) as caught:
                await limit_preview(request)
            assert caught.value.status_code == status
        else:
            await limit_preview(request)


async def test_rate_limiter_failure_denies_preview_requests():
    request = Request({"type": "http", "client": ("127.0.0.1", 5000)})
    with patch(
        "app.api.preview_limits.Redis.from_url", side_effect=RedisConnectionError
    ):
        with pytest.raises(HTTPException) as caught:
            await limit_preview(request)
        assert caught.value.status_code == 503


def test_preview_links_expire_after_five_minutes():
    from unittest.mock import Mock

    from app.infrastructure.adapters.r2 import R2Storage

    storage = object.__new__(R2Storage)
    storage.bucket = "private-media"
    storage.client = Mock()
    storage.client.generate_presigned_url.return_value = "https://signed.example/video"
    assert (
        storage.preview_url("published/episode.mp4") == "https://signed.example/video"
    )
    storage.client.generate_presigned_url.assert_called_once_with(
        "get_object",
        Params={"Bucket": "private-media", "Key": "published/episode.mp4"},
        ExpiresIn=300,
    )


def test_public_routes_work_without_auth_and_return_no_paid_urls():
    from fastapi.testclient import TestClient

    from app.api.dependencies import rating_service
    from app.api.routes.public_series import public_service
    from app.main import app

    ratings = AsyncMock()
    ratings.series_averages.return_value = {}
    app.dependency_overrides[public_service] = lambda: PublicSeriesService(
        Store(),
        lambda key, revision=None: f"https://signed.example/{key}",
    )
    app.dependency_overrides[rating_service] = lambda: ratings
    app.dependency_overrides[limit_preview] = lambda: None
    try:
        with TestClient(app) as client:
            response = client.get(f"/api/v1/public/series/{SERIES}/playlist?limit=999")
            assert response.status_code == 200
            assert response.headers["cache-control"] == "private, no-store"
            assert [item["episode_number"] for item in response.json()] == [1, 2]
            assert "videos/3.mp4" not in response.text
            assert client.get("/api/v1/public/series/not-a-uuid").status_code == 422
            assert client.get(f"/api/v1/series/{SERIES}").status_code == 401
    finally:
        app.dependency_overrides.clear()
