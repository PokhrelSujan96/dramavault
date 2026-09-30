export type SeriesCard = {
  series_id: string;
  title: string;
  description: string;
  genre: string;
  thumbnail_url: string;
  episode_count: number;
  free_episode_count?: number | null;
};

export type Episode = {
  episode_id: string;
  episode_number: number;
  title: string;
  description?: string;
  duration_seconds: number;
  thumbnail_url: string;
  video_url?: string;
  likes?: number;
  locked?: boolean;
};

export type Profile = {
  id: string;
  email: string | null;
  display_name: string;
  avatar_url: string | null;
  coins: number;
  bonus_coins: number;
  vip_expires_at: string | null;
};

export type HomeFeed = {
  featured: SeriesCard[];
  trending: SeriesCard[];
  genres: { genre: string; items: SeriesCard[] }[];
};

export type SeriesDetails = SeriesCard & { episodes: Episode[]; rating_average?: number | null; rating_count?: number };

export type PlaylistItem = Episode & {
  series_id: string;
  description: string;
  genre: string;
  video_url: string;
  published_count: number;
  my_rating?: number | null;
  liked?: boolean;
  comments?: number;
  likes: number;
};
