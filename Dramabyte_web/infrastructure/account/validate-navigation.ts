import type { Profile } from "@/domain/models";
import type { ReferralSummary, WatchHistory } from "@/domain/account/navigation";
import { safeArtwork } from "@/infrastructure/home/validate-feed";

const record = (value: unknown): value is Record<string, unknown> => !!value && typeof value === "object" && !Array.isArray(value);
const validCount = (value: unknown): value is number => typeof value === "number" && Number.isSafeInteger(value) && value >= 0;
const count = (value: unknown) => typeof value === "number" && Number.isSafeInteger(value) && value >= 0 ? value : 0;
const text = (value: unknown, length = 240) => typeof value === "string" ? value.slice(0, length) : "";
const uuid = (value: unknown): value is string => typeof value === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);

export function parseProfile(value: unknown): Profile {
  if (!record(value) || !uuid(value.id) || !validCount(value.coins) || !validCount(value.bonus_coins)) throw new Error("Invalid profile");
  const expires = text(value.vip_expires_at, 50);
  return {
    id: value.id, display_name: text(value.display_name), email: text(value.email, 320) || null,
    avatar_url: safeArtwork(value.avatar_url) || null, coins: count(value.coins),
    bonus_coins: count(value.bonus_coins), vip_expires_at: expires && Number.isFinite(Date.parse(expires)) ? expires : null,
  };
}

export function parseHistory(value: unknown): WatchHistory[] {
  if (!record(value) || !Array.isArray(value.items)) throw new Error("Invalid history");
  return value.items.slice(0, 10).flatMap((item) => {
    if (!record(item) || !uuid(item.episode_id) || !uuid(item.series_id)) return [];
    return [{ episode_id: item.episode_id, series_id: item.series_id, title: text(item.title),
      episode_number: count(item.episode_number), thumbnail_url: safeArtwork(item.thumbnail_url),
      position_seconds: count(item.position_seconds), duration_seconds: count(item.duration_seconds) }];
  });
}

export function parseReferral(value: unknown): ReferralSummary {
  if (!record(value) || typeof value.code !== "string" || !/^[A-Za-z0-9]{6,12}$/.test(value.code)) throw new Error("Invalid referral");
  if (![value.invited, value.purchased, value.earned, value.signup_reward, value.purchase_reward].every(validCount)) throw new Error("Invalid referral totals");
  return { code: value.code, invited: count(value.invited), purchased: count(value.purchased), earned: count(value.earned), signup_reward: count(value.signup_reward), purchase_reward: count(value.purchase_reward) };
}
