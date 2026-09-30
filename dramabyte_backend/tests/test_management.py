from datetime import UTC, datetime
from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.api.management_schemas import EpisodeBody, VideoUpdate
from app.application.auth import AuthService
from app.domain.profile import AuthError, AuthSession, Profile


class InactiveProfiles:
    async def touch_login(self, user_id):
        return Profile(id=user_id, created_at=datetime.now(UTC), is_suspended=True)


async def test_suspended_user_cannot_receive_session() -> None:
    service = AuthService(None, InactiveProfiles())
    session = AuthSession(
        user_id=uuid4(),
        access_token=str(uuid4()),
        refresh_token=str(uuid4()),
        expires_in=3600,
    )
    with pytest.raises(AuthError, match="inactive"):
        await service._complete(session)


def test_episode_requires_positive_number() -> None:
    with pytest.raises(ValidationError):
        EpisodeBody(project_id=uuid4(), episode_number=0)


def test_admin_cannot_set_video_to_generating() -> None:
    with pytest.raises(ValidationError):
        VideoUpdate(status="generating")
