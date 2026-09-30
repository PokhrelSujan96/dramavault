from datetime import UTC, datetime
from unittest.mock import AsyncMock, patch
from uuid import uuid4

from fastapi.testclient import TestClient

from app.api.dependencies import comment_service
from app.api.preview_limits import limit_preview
from app.domain.comments import Comment, CommentPage
from app.infrastructure.database import get_database
from app.main import app

EPISODE = uuid4()
COMMENT = uuid4()


def test_guests_read_comments_without_author_account_ids_or_private_flags():
    service = AsyncMock()
    page = CommentPage(
        items=[
            Comment(
                id=str(COMMENT),
                episode_id=str(EPISODE),
                body="<script>example</script>",
                created_at=datetime.now(UTC),
                author_id=str(uuid4()),
                author_name="Viewer",
                author_avatar="https://private.example/avatar",
                liked=True,
                is_mine=True,
            )
        ],
        next_cursor=None,
    )
    service.page.return_value = page
    service.replies.return_value = page
    app.dependency_overrides[comment_service] = lambda: service
    app.dependency_overrides[get_database] = lambda: object()
    app.dependency_overrides[limit_preview] = lambda: None
    try:
        with patch("app.api.routes.public_comments.PublicCommentAccess") as access:
            access.return_value.published = AsyncMock(return_value=True)
            access.return_value.parent_episode = AsyncMock(return_value=EPISODE)
            with TestClient(app) as client:
                for route in (f"episodes/{EPISODE}", f"{COMMENT}/replies"):
                    response = client.get(f"/api/v1/public/comments/{route}")
                    assert response.status_code == 200
                    assert response.headers["cache-control"] == "no-store"
                    data = response.json()
                    assert data["can_post"] is False
                    assert data["items"][0]["body"] == "<script>example</script>"
                    assert (
                        not {"author_id", "author_avatar", "liked", "is_mine"}
                        & data["items"][0].keys()
                    )
                access.return_value.published.return_value = False
                assert (
                    client.get(
                        f"/api/v1/public/comments/episodes/{EPISODE}"
                    ).status_code
                    == 404
                )
                assert (
                    client.get(
                        f"/api/v1/public/comments/episodes/{EPISODE}?limit=500"
                    ).status_code
                    == 422
                )
                assert (
                    client.post(
                        f"/api/v1/comments/episodes/{EPISODE}", json={"body": "Hello"}
                    ).status_code
                    == 401
                )
    finally:
        app.dependency_overrides.clear()
