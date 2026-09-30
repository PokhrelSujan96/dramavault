import "server-only";
import { cookies } from "next/headers";
import { publicRequest } from "@/infrastructure/api/public-request";
import { authenticatedRequest } from "@/infrastructure/api/authenticated";
import { validId } from "@/domain/player/contracts";
import { parseDetails, parsePlaylist } from "./validate-player";

async function requestSeries(path: string) {
  if ((await cookies()).get("dramabyte_access")?.value) return authenticatedRequest(path);
  return publicRequest(`/public${path}`);
}
export async function loadSeries(id: string) {
  if (!validId(id)) return null;
  const series = parseDetails(await requestSeries(`/series/${id}`));
  if (series.series_id !== id) throw new Error("Mismatched series");
  return series;
}
export async function loadEpisode(seriesId: string, episodeId: string) {
  if (!validId(seriesId) || !validId(episodeId)) return null;
  const series = await loadSeries(seriesId);
  const episode = series?.episodes.find((item) => item.episode_id === episodeId);
  if (!series || !episode) return null;
  const guest = !(await cookies()).get("dramabyte_access")?.value;
  if (guest && ![1, 2].includes(episode.episode_number)) return { series, locked: true, current: undefined };
  if (episode.locked) return { series, locked: true, current: undefined };
  const playlist = parsePlaylist(await requestSeries(`/series/${seriesId}/playlist`), seriesId);
  const current = playlist.find((item) => item.episode_id === episodeId && item.episode_number === episode.episode_number);
  return { series, locked: false, current };
}
