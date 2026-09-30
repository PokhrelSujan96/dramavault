export type UserProfile = {
  id: string; email: string; display_name: string; avatar_url?: string;
  country?: string; language: string; coins: number; bonus_coins: number;
  auth_provider: string; vip_expires_at?: string; is_onboarded: boolean;
  is_suspended: boolean; deleted_at?: string; created_at: string; last_login_at?: string;
};
export type CoinTransaction = { id: string; amount: number; reason: string; balance_after: number; created_at: string };
export type Series = {
  id: string; title: string; description: string; thumbnail_url?: string; genre?: string;
  target_episode_count?: number; target_episode_seconds?: number; episode_count?: number;
  published_episodes?: number; duration_seconds?: number; views?: number; likes?: number;
  comments?: number; rating?: number | null; rating_count?: number;
};
export type RecordList<T> = { items: T[]; total?: number };
