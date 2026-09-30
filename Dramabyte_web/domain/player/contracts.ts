export const validId = (value: unknown): value is string => typeof value === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
export interface EpisodeComment {
  id: string;
  episode_id: string;
  parent_id: string | null;
  body: string;
  author_name: string;
  created_at: string;
  like_count: number;
  reply_count: number;
  liked: boolean;
  is_mine: boolean;
  pending?: boolean;
}
export interface CommentPage { items: EpisodeComment[]; can_post?: boolean; next_cursor: string | null }
export type PlayerResult<T> = { data: T; error?: never; signIn?: never } | { data?: never; error: string; signIn?: boolean };
