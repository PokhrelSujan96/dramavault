from collections.abc import Callable
from typing import Any, Protocol
from uuid import UUID

from pydantic import ValidationError

from app.application.discover import to_discover_item
from app.domain.discover import DiscoverItem
from app.domain.series import EpisodeSummary, SeriesDetails, SeriesError


class SeriesStore(Protocol):
    async def details(self, series_id: UUID) -> dict[str, Any] | None: ...

    async def playlist(self, series_id: UUID) -> list[dict[str, Any]]: ...


class SeriesService:
    def __init__(self, store: SeriesStore, sign: Callable[..., str]) -> None:
        self.store = store
        self.sign = sign

    async def details(self, series_id: UUID) -> SeriesDetails:
        raw = await self.store.details(series_id)
        free = raw.get("free_episode_count") if raw else None
        episodes = []
        for item in (raw.get("episodes") if raw else None) or []:
            try:
                episode = EpisodeSummary.model_validate(item)
            except ValidationError:
                continue
            episode.locked = isinstance(free, int) and episode.episode_number > free
            episodes.append(episode)
        if not raw or not episodes:
            raise SeriesError("series_not_found")
        return SeriesDetails(
            series_id=str(raw["series_id"]),
            title=raw["title"],
            description=raw.get("description") or "",
            genre=raw.get("genre") or "",
            thumbnail_url=raw.get("thumbnail_url") or "",
            episode_count=len(episodes),
            free_episode_count=free if isinstance(free, int) else None,
            episodes=episodes,
        )

    async def playlist(self, series_id: UUID) -> list[DiscoverItem]:
        rows = await self.store.playlist(series_id)
        return [to_discover_item(row, self.sign) for row in rows]
