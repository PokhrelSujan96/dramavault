from datetime import datetime

from pydantic import BaseModel


class HistoryError(Exception):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


class HistoryItem(BaseModel):
    episode_id: str
    series_id: str
    title: str
    episode_number: int
    thumbnail_url: str
    position_seconds: int
    duration_seconds: int
    watched_at: datetime


class HistoryPage(BaseModel):
    items: list[HistoryItem]
    next_cursor: str | None
