from pydantic import BaseModel, Field


class DiscoverError(Exception):
    pass


class DiscoverItem(BaseModel):
    series_id: str
    episode_id: str
    title: str
    description: str
    genre: str
    thumbnail_url: str
    episode_number: int
    duration_seconds: int
    aspect_ratio: str
    video_url: str
    video_revision: str = ""
    video_width: int = 1080
    video_height: int = 1920
    video_variants: dict[str, str] = Field(default_factory=dict)
    published_count: int
    likes: int
    views: int = 0
    liked: bool = False
    comments: int = 0
    rating_average: float | None = None
    rating_count: int = 0
    my_rating: int | None = None


class DiscoverPage(BaseModel):
    items: list[DiscoverItem]
    next_cursor: str | None
