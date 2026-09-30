from pydantic import BaseModel


class SeriesError(Exception):
    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


class EpisodeSummary(BaseModel):
    episode_id: str
    episode_number: int
    title: str = ""
    duration_seconds: int = 0
    thumbnail_url: str = ""
    locked: bool = False


class SeriesDetails(BaseModel):
    series_id: str
    title: str
    description: str = ""
    genre: str = ""
    thumbnail_url: str = ""
    episode_count: int
    free_episode_count: int | None = None
    rating_average: float | None = None
    rating_count: int = 0
    my_rating: int | None = None
    episodes: list[EpisodeSummary]
