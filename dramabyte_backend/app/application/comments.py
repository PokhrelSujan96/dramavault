import base64
import re
from datetime import datetime
from typing import Any, Literal, Protocol
from uuid import UUID

from pydantic import ValidationError

from app.domain.comments import Comment, CommentError, CommentPage

Sort = Literal["top", "new"]
_CONTROL = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")


class CommentStore(Protocol):
    async def list_new(
        self,
        viewer: UUID,
        episode: UUID,
        after: tuple[datetime, UUID] | None,
        limit: int,
    ) -> list[dict[str, Any]]: ...

    async def list_top(
        self,
        viewer: UUID,
        episode: UUID,
        after: tuple[int, datetime, UUID] | None,
        limit: int,
    ) -> list[dict[str, Any]]: ...

    async def list_replies(
        self,
        viewer: UUID,
        parent: UUID,
        after: tuple[datetime, UUID] | None,
        limit: int,
    ) -> list[dict[str, Any]]: ...

    async def by_ids(self, viewer: UUID, ids: list[UUID]) -> list[dict[str, Any]]: ...

    async def post(
        self,
        user: UUID,
        episode: UUID,
        parent: UUID | None,
        body: str,
        key: UUID | None,
        max_per_minute: int,
        max_length: int,
    ) -> dict[str, Any]: ...

    async def toggle_like(
        self, user: UUID, comment: UUID, liked: bool
    ) -> dict[str, Any]: ...

    async def delete(self, user: UUID, comment: UUID) -> str: ...

    async def report(self, user: UUID, comment: UUID, reason: str) -> str: ...


def encode_cursor(*parts: object) -> str:
    return base64.urlsafe_b64encode("|".join(str(p) for p in parts).encode()).decode()


def decode_cursor(cursor: str, size: int) -> list[str]:
    try:
        parts = base64.urlsafe_b64decode(cursor).decode().split("|")
    except (ValueError, UnicodeDecodeError) as error:
        raise CommentError("invalid_cursor") from error
    if len(parts) != size:
        raise CommentError("invalid_cursor")
    return parts


def clean_body(body: str) -> str:
    return _CONTROL.sub("", body).strip()


class CommentService:
    def __init__(
        self, store: CommentStore, max_length: int, max_per_minute: int
    ) -> None:
        self.store = store
        self.max_length = max_length
        self.max_per_minute = max_per_minute

    async def page(
        self, viewer: UUID, episode: UUID, sort: Sort, cursor: str | None, limit: int
    ) -> CommentPage:
        rows = await self._fetch(viewer, episode, sort, cursor, limit + 1)
        visible = rows[:limit]
        last = visible[-1] if visible else None
        more = len(rows) > limit and last is not None
        token = None
        if more and last is not None:
            token = (
                encode_cursor(last["created_at"], last["id"])
                if sort == "new"
                else encode_cursor(last["like_count"], last["created_at"], last["id"])
            )
        return CommentPage(items=self._comments(visible, viewer), next_cursor=token)

    async def replies(
        self, viewer: UUID, comment: UUID, cursor: str | None, limit: int
    ) -> CommentPage:
        after = None
        if cursor:
            created, identifier = decode_cursor(cursor, 2)
            after = (_time(created), _uuid(identifier))
        rows = await self.store.list_replies(viewer, comment, after, limit + 1)
        visible = rows[:limit]
        last = visible[-1] if visible else None
        more = len(rows) > limit and last is not None
        token = encode_cursor(last["created_at"], last["id"]) if more and last else None
        return CommentPage(items=self._comments(visible, viewer), next_cursor=token)

    async def post(
        self,
        viewer: UUID,
        episode: UUID,
        body: str,
        parent: UUID | None,
        key: UUID | None,
    ) -> Comment:
        text = clean_body(body)
        if not text or len(text) > self.max_length:
            raise CommentError("invalid_body")
        result = await self.store.post(
            viewer, episode, parent, text, key, self.max_per_minute, self.max_length
        )
        if result.get("code") != "ok":
            raise CommentError(str(result.get("code")))
        rows = await self.store.by_ids(viewer, [UUID(str(result["id"]))])
        comments = self._comments(rows, viewer)
        if not comments:
            raise CommentError("comment_not_found")
        return comments[0]

    async def like(self, viewer: UUID, comment: UUID, liked: bool) -> int:
        result = await self.store.toggle_like(viewer, comment, liked)
        if result.get("code") != "ok":
            raise CommentError(str(result.get("code")))
        return int(result["like_count"])

    async def delete(self, viewer: UUID, comment: UUID) -> None:
        result = await self.store.delete(viewer, comment)
        if result != "ok":
            raise CommentError(result)

    async def report(self, viewer: UUID, comment: UUID, reason: str) -> None:
        text = clean_body(reason)[:200]
        if not text:
            raise CommentError("invalid_body")
        result = await self.store.report(viewer, comment, text)
        if result != "ok":
            raise CommentError(result)

    async def _fetch(
        self, viewer: UUID, episode: UUID, sort: Sort, cursor: str | None, limit: int
    ) -> list[dict[str, Any]]:
        if sort == "new":
            after = None
            if cursor:
                created, identifier = decode_cursor(cursor, 2)
                after = (_time(created), _uuid(identifier))
            return await self.store.list_new(viewer, episode, after, limit)
        top_after = None
        if cursor:
            likes, created, identifier = decode_cursor(cursor, 3)
            top_after = (_int(likes), _time(created), _uuid(identifier))
        return await self.store.list_top(viewer, episode, top_after, limit)

    @staticmethod
    def _comments(rows: list[dict[str, Any]], viewer: UUID) -> list[Comment]:
        comments = []
        for row in rows:
            try:
                comment = Comment.model_validate(row)
            except ValidationError:
                continue
            comment.is_mine = comment.author_id == str(viewer)
            comments.append(comment)
        return comments


def _time(value: str) -> datetime:
    try:
        return datetime.fromisoformat(value)
    except ValueError as error:
        raise CommentError("invalid_cursor") from error


def _uuid(value: str) -> UUID:
    try:
        return UUID(value)
    except ValueError as error:
        raise CommentError("invalid_cursor") from error


def _int(value: str) -> int:
    try:
        return int(value)
    except ValueError as error:
        raise CommentError("invalid_cursor") from error
