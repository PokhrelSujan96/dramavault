import base64
from collections.abc import Callable
from datetime import datetime
from typing import Any, Protocol
from uuid import UUID

from app.domain.discover import DiscoverError, DiscoverItem, DiscoverPage


class DiscoverStore(Protocol):
    async def rows(
        self, after: tuple[datetime, UUID] | None, limit: int
    ) -> list[dict[str, Any]]: ...


def discover_video_url(row: dict[str, Any], public_url: Callable[..., str]) -> str:
    key = row.get("video_key") or row.get("published_key")
    if not key:
        raise DiscoverError("Published episode video is unavailable")
    revision = row.get("video_revision") or row.get("published_revision")
    return public_url(str(key), str(revision) if revision else None)


def discover_video_revision(row: dict[str, Any]) -> str:
    return str(row.get("video_revision") or row.get("published_revision") or "")


def encode_cursor(created_at: str, series_id: str) -> str:
    return base64.urlsafe_b64encode(f"{created_at}|{series_id}".encode()).decode()


def decode_cursor(cursor: str) -> tuple[datetime, UUID]:
    try:
        created_at, series_id = base64.urlsafe_b64decode(cursor).decode().split("|")
        return datetime.fromisoformat(created_at), UUID(series_id)
    except ValueError as error:
        raise DiscoverError("Invalid cursor") from error


def to_discover_item(row: dict[str, Any], sign: Callable[..., str]) -> DiscoverItem:
    raw_variants = row.get("video_variants")
    variants = (
        {
            str(language): sign(
                str(track["key"]), str(track.get("revision", "")) or None
            )
            for language, track in raw_variants.items()
            if isinstance(raw_variants, dict)
            and isinstance(track, dict)
            and track.get("key")
        }
        if isinstance(raw_variants, dict)
        else {}
    )
    return DiscoverItem(
        series_id=str(row["series_id"]),
        episode_id=str(row["episode_id"]),
        title=row["series_title"],
        description=row["episode_description"] or row["series_description"],
        genre=row["genre"],
        thumbnail_url=row["episode_thumbnail"] or row["series_thumbnail"],
        episode_number=row["episode_number"],
        duration_seconds=row["duration_seconds"],
        aspect_ratio=row["aspect_ratio"],
        video_url=discover_video_url(row, sign),
        video_revision=discover_video_revision(row),
        video_width=int(row.get("video_width") or 1080),
        video_height=int(row.get("video_height") or 1920),
        video_variants=variants,
        published_count=row["published_count"],
        likes=row["likes"],
    )


class DiscoverService:
    def __init__(self, store: DiscoverStore, sign: Callable[..., str]) -> None:
        self.store = store
        self.sign = sign

    async def page(self, cursor: str | None, limit: int) -> DiscoverPage:
        after = decode_cursor(cursor) if cursor else None
        rows = await self.store.rows(after, limit + 1)
        visible = rows[:limit]
        last = visible[-1] if visible else None
        more = len(rows) > limit and last is not None
        return DiscoverPage(
            items=[self._item(row) for row in visible],
            next_cursor=encode_cursor(
                str(last["series_created_at"]), str(last["series_id"])
            )
            if more and last
            else None,
        )

    def _item(self, row: dict[str, Any]) -> DiscoverItem:
        return to_discover_item(row, self.sign)
