export interface HomeTitle {
  id: string;
  title: string;
  image: string;
  genre: string;
  episodeCount: number;
  freeEpisodeCount: number | null;
  description: string;
  saved: boolean;
}

export interface HomeCatalog {
  featured: HomeTitle[];
  trending: HomeTitle[];
  all: HomeTitle[];
  genres: { genre: string; items: HomeTitle[] }[];
}
