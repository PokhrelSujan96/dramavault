import type { HomeFeed, SeriesCard } from "@/domain/models";

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const record = (value: unknown): value is Record<string, unknown> => !!value && typeof value === "object" && !Array.isArray(value);
const text = (value: unknown, max: number) => typeof value === "string" ? value.slice(0, max).trim() : "";
const count = (value: unknown) => typeof value === "number" && Number.isSafeInteger(value) && value >= 0 ? Math.min(value, 100000) : 0;

export function safeArtwork(value: unknown): string {
  const source = text(value, 4096);
  if (!source || /[\\\u0000-\u001f]/.test(source)) return "";
  if (source.startsWith("/")) {
    if (!/^\/(home|images|media|uploads)\//.test(source) || /%2f|%5c|%2e/i.test(source)) return "";
    return source;
  }
  try {
    const url = new URL(source);
    if (url.protocol !== "https:" || url.username || url.password) return "";
    return url.href;
  } catch {
    return "";
  }
}

export function parseSeries(value: unknown, limit = 100): SeriesCard[] {
  if (!Array.isArray(value)) throw new Error("Invalid series collection");
  const seen = new Set<string>();
  return value.slice(0, limit).flatMap((item) => {
    if (!record(item)) return [];
    const id = typeof item.series_id === "string" ? item.series_id.toLowerCase() : "";
    const title = text(item.title, 240);
    if (!uuid.test(id) || !title || seen.has(id)) return [];
    seen.add(id);
    return [{
      series_id: id, title, description: text(item.description, 4000),
      genre: text(item.genre, 100) || "Drama", thumbnail_url: safeArtwork(item.thumbnail_url),
      episode_count: count(item.episode_count),
      free_episode_count: item.free_episode_count == null ? null : count(item.free_episode_count),
    }];
  });
}

export function parseHomeFeed(value: unknown): HomeFeed {
  if (!record(value) || !Array.isArray(value.genres)) throw new Error("Invalid home feed");
  const seen = new Set<string>();
  return {
    featured: parseSeries(value.featured), trending: parseSeries(value.trending),
    genres: value.genres.slice(0, 30).flatMap((rail) => {
      if (!record(rail)) return [];
      const genre = text(rail.genre, 100);
      if (!genre || seen.has(genre)) return [];
      seen.add(genre);
      return [{ genre, items: parseSeries(rail.items) }];
    }),
  };
}
