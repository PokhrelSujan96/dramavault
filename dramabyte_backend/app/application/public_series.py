from collections.abc import Callable
from typing import Any, Protocol
from uuid import UUID

from app.application.discover import to_discover_item
from app.application.series import SeriesService
from app.domain.discover import DiscoverItem
from app.domain.series import SeriesDetails


class PublicSeriesStore(Protocol):
    async def details(self, series_id: UUID) -> dict[str, Any] | None: ...

    async def playlist(self, series_id: UUID) -> list[dict[str, Any]]: ...

    async def public_playlist(self, series_id: UUID) -> list[dict[str, Any]]: ...


class PublicSeriesService:
    def __init__(self, store: PublicSeriesStore, sign: Callable[..., str]) -> None:
        self.store = store
        self.sign = sign

    async def details(self, series_id: UUID) -> SeriesDetails:
        details = await SeriesService(self.store, self.sign).details(series_id)
        return details.model_copy(
            update={
                "free_episode_count": 2,
                "episodes": [
                    episode.model_copy(
                        update={
                            "locked": not 1 <= episode.episode_number <= 2,
                        }
                    )
                    for episode in details.episodes
                ],
            }
        )

    async def playlist(self, series_id: UUID) -> list[DiscoverItem]:
        details = await self.details(series_id)
        allowed = {
            episode.episode_id: episode.episode_number
            for episode in details.episodes
            if not episode.locked
        }
        rows = await self.store.public_playlist(series_id)
        return [
            to_discover_item(row, self.sign)
            for row in rows
            if str(row.get("series_id")) == str(series_id)
            and str(row.get("episode_id")) in allowed
            and type(row.get("episode_number")) is int
            and row["episode_number"] == allowed[str(row["episode_id"])]
        ]
