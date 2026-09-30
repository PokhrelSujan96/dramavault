import { cookies } from "next/headers";
import { HomeFeed, PlaylistItem, Profile, SeriesCard, SeriesDetails } from "@/domain/models";
import { mockSeries } from "@/infrastructure/mock-data";

const baseUrl = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000/api/v1";

async function request<T>(path: string, fallback: T): Promise<T> {
  const token = (await cookies()).get("dramabyte_access")?.value;
  try {
    const response = await fetch(`${baseUrl}${path}`, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      next: { revalidate: token ? 0 : 60 },
    });
    if (!response.ok) return fallback;
    return (await response.json()) as T;
  } catch {
    return fallback;
  }
}

export const getHome = () => request<HomeFeed>("/home", { featured: [], trending: [], genres: [] });
export const searchSeries = (query: string) => request<SeriesCard[]>(`/search?q=${encodeURIComponent(query)}`, []);
export const getProfile = () => request<Profile>("/profile/me", { id: "demo", email: "viewer@dramabyte.com", display_name: "DramaByte Viewer", avatar_url: null, coins: 0, bonus_coins: 5, vip_expires_at: null });
export const getSeries = (id: string) => request<SeriesDetails>(`/series/${id}`, { ...mockSeries.find((item) => item.series_id === id) ?? mockSeries[0], episodes: Array.from({ length: 15 }, (_, index) => ({ episode_id: `${id}-${index + 1}`, episode_number: index + 1, title: `Episode ${index + 1}`, duration_seconds: 60, thumbnail_url: "", locked: index > 2 })) });
export const getSeriesPlaylist = (id: string) => request<PlaylistItem[]>(`/series/${id}/playlist`, []);
