import type { PlaylistItem, SeriesDetails } from "@/domain/models";
import { validId, type EpisodeComment, type CommentPage } from "@/domain/player/contracts";
import { safeArtwork, parseSeries } from "@/infrastructure/home/validate-feed";

const record = (value: unknown): value is Record<string, unknown> => !!value && typeof value === "object" && !Array.isArray(value);
const text = (value: unknown, max = 4000) => typeof value === "string" ? value.slice(0, max) : "";
const count = (value: unknown) => typeof value === "number" && Number.isSafeInteger(value) && value >= 0 ? value : 0;
export function parseDetails(value: unknown): SeriesDetails {
  if (!record(value) || !Array.isArray(value.episodes)) throw new Error("Invalid series");
  const series = parseSeries([value])[0];
  if (!series) throw new Error("Invalid series");
  return { ...series, rating_average: typeof value.rating_average === "number" && Number.isFinite(value.rating_average) && value.rating_average >= 1 && value.rating_average <= 10 ? value.rating_average : null, rating_count: count(value.rating_count), episodes: value.episodes.slice(0, 500).flatMap((item) => {
    if (!record(item) || !validId(item.episode_id) || typeof item.locked !== "boolean") return [];
    return [{ episode_id: item.episode_id, episode_number: count(item.episode_number), title: text(item.title, 240), duration_seconds: count(item.duration_seconds), thumbnail_url: safeArtwork(item.thumbnail_url), locked: item.locked === true }];
  }) };
}
export function parsePlaylist(value: unknown, seriesId: string): PlaylistItem[] {
  if (!Array.isArray(value)) throw new Error("Invalid playlist");
  return value.slice(0, 500).flatMap((item) => {
    if (!record(item) || !validId(item.episode_id) || item.series_id !== seriesId) return [];
    return [{ series_id: seriesId, episode_id: item.episode_id, title: text(item.title, 240), description: text(item.description), genre: text(item.genre, 100), episode_number: count(item.episode_number), duration_seconds: count(item.duration_seconds), thumbnail_url: safeArtwork(item.thumbnail_url), video_url: safeArtwork(item.video_url), published_count: count(item.published_count), likes: count(item.likes), my_rating: typeof item.my_rating === "number" && Number.isInteger(item.my_rating) && item.my_rating >= 1 && item.my_rating <= 10 ? item.my_rating : null, liked: item.liked === true, comments: count(item.comments) }];
  });
}
export function parseComment(value: unknown): EpisodeComment {
  if (!record(value) || !validId(value.id) || !validId(value.episode_id)) throw new Error("Invalid comment");
  return { id: value.id, episode_id: value.episode_id, parent_id: validId(value.parent_id) ? value.parent_id : null, body: text(value.body, 500), author_name: text(value.author_name, 240) || "Viewer", created_at: text(value.created_at, 50), like_count: count(value.like_count), reply_count: count(value.reply_count), liked: value.liked === true, is_mine: value.is_mine === true };
}
export function parseComments(value: unknown): CommentPage {
  if (!record(value) || !Array.isArray(value.items)) throw new Error("Invalid comments");
  return { items: value.items.slice(0, 50).map(parseComment), next_cursor: typeof value.next_cursor === "string" ? value.next_cursor.slice(0, 300) : null };
}
