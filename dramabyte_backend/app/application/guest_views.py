from typing import Protocol
from uuid import UUID


class GuestViewStore(Protocol):
    async def record(self, episode: UUID, event: UUID) -> str: ...


class GuestViewService:
    def __init__(self, store: GuestViewStore) -> None:
        self.store = store

    async def record(self, episode: UUID, event: UUID) -> bool:
        return await self.store.record(episode, event) in {"ok", "duplicate"}
