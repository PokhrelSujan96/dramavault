from uuid import uuid4

import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.api.management_schemas import EpisodeBody, SeriesBody
from app.api.routes.engagement import RatingBody, ViewBody
from app.api.routes.episode_upload import probe_duration


def test_default_series_plan_is_fifteen_minutes() -> None:
    series = SeriesBody(title="The Last Train Home")
    assert series.target_episode_count == 15
    assert series.target_episode_seconds == 60
    assert series.target_episode_count * series.target_episode_seconds == 900


def test_episode_has_independent_metadata() -> None:
    episode = EpisodeBody(
        project_id=uuid4(),
        episode_number=2,
        title="The Passenger",
        description="Maya discovers who is waiting.",
        duration_seconds=62,
    )
    assert episode.title == "The Passenger"
    assert episode.duration_seconds == 62


def test_rating_scale_is_one_to_ten() -> None:
    assert RatingBody(rating=10).rating == 10
    for invalid in (0, 11):
        with pytest.raises(ValidationError):
            RatingBody(rating=invalid)


def test_a_view_requires_at_least_ten_seconds() -> None:
    with pytest.raises(ValidationError):
        ViewBody(session_id=uuid4(), watched_seconds=1)


async def test_invalid_video_is_rejected(tmp_path) -> None:
    path = tmp_path / "invalid.mp4"
    path.write_bytes(b"invalid media")
    with pytest.raises(HTTPException) as error:
        await probe_duration(path)
    assert error.value.status_code == 422
