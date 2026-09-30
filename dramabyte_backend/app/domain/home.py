from pydantic import BaseModel


class SeriesCard(BaseModel):
    series_id: str
    title: str
    description: str = ""
    genre: str = "Drama"
    thumbnail_url: str = ""
    episode_count: int = 0
    views: int = 0
    rating_average: float | None = None
    rating_count: int = 0
    free_episode_count: int | None = None


class GenreRail(BaseModel):
    genre: str
    items: list[SeriesCard]


class HomeFeed(BaseModel):
    featured: list[SeriesCard]
    trending: list[SeriesCard]
    genres: list[GenreRail]
