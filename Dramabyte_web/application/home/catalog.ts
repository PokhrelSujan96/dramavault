import type { HomeCatalog, HomeTitle } from "@/domain/home/title";
import type { HomeFeed, SeriesCard } from "@/domain/models";

export function createHomeCatalog(feed: HomeFeed, savedIds: string[]): HomeCatalog {
  const saved = new Set(savedIds);
  const convert = (item: SeriesCard): HomeTitle => ({
    id: item.series_id, title: item.title, image: item.thumbnail_url,
    genre: item.genre, description: item.description, episodeCount: item.episode_count,
    freeEpisodeCount: item.free_episode_count ?? null, saved: saved.has(item.series_id),
  });
  const featured = feed.featured.map(convert);
  const trending = feed.trending.map(convert);
  const genres = feed.genres.map((rail) => ({ genre: rail.genre, items: rail.items.map(convert) })).filter((rail) => rail.items.length);
  const all = Array.from(new Map([...featured, ...trending, ...genres.flatMap((rail) => rail.items)].map((item) => [item.id, item])).values());
  return { featured, trending, genres, all };
}
