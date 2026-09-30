from datetime import datetime

from pydantic import BaseModel


class LibraryError(Exception):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


class LibraryItem(BaseModel):
    series_id: str
    title: str
    description: str = ""
    genre: str = ""
    thumbnail_url: str = ""
    episode_count: int = 0
    free_episode_count: int | None = None
    saved_at: datetime
