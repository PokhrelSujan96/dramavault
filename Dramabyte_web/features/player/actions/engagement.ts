"use server";

import { BackendError, authenticatedRequest } from "@/infrastructure/api/authenticated";
import { validId, type PlayerResult } from "@/domain/player/contracts";
import { loadEpisode } from "@/infrastructure/player/watch-repository";

export async function setEpisodeLike(id: string, liked: boolean): Promise<PlayerResult<null>> {
  if (!validId(id) || typeof liked !== "boolean") return { error: "Invalid episode." };
  try { await authenticatedRequest(`/engagement/episodes/${id}/likes`, "POST", { liked }); return { data: null }; }
  catch (error) { return { error: error instanceof BackendError && error.status === 401 ? "Please sign in again to like this episode." : "Couldn’t update your like. Please try again.", signIn: error instanceof BackendError && error.status === 401 }; }
}
export async function refreshPlayback(seriesId: string, episodeId: string): Promise<PlayerResult<string>> {
  try {
    const episode = await loadEpisode(seriesId, episodeId);
    if (!episode?.current?.video_url || episode.locked) return { error: "This episode isn’t available to play." };
    return { data: episode.current.video_url };
  } catch (error) { return { error: "Couldn’t load this video. Please try again.", signIn: error instanceof BackendError && error.status === 401 }; }
}
