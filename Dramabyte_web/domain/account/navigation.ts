import type { Profile, SeriesCard } from "@/domain/models";

export type AccountPanel = "library" | "profile" | "referral" | "history";
export interface WatchHistory {
  episode_id: string;
  series_id: string;
  title: string;
  episode_number: number;
  thumbnail_url: string;
  position_seconds: number;
  duration_seconds: number;
}
export interface ReferralSummary {
  code: string;
  invited: number;
  purchased: number;
  earned: number;
  signup_reward: number;
  purchase_reward: number;
}
export interface NavigationData {
  profile?: Profile;
  library?: SeriesCard[];
  history?: WatchHistory[];
  referral?: ReferralSummary;
  error?: string;
  signIn?: boolean;
}
