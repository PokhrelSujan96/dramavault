"use server";

import { authenticatedRequest, BackendError } from "@/infrastructure/api/authenticated";
import { validId, type PlayerResult } from "@/domain/player/contracts";

export type EpisodeRating = { average: number | null; count: number; my_rating: number | null };
export async function rateEpisode(id: string, rating: number | null): Promise<PlayerResult<EpisodeRating>> {
  if (!validId(id) || (rating !== null && (!Number.isInteger(rating) || rating < 1 || rating > 10))) return { error: "Invalid rating." };
  try {
    const data = await authenticatedRequest(`/ratings/episodes/${id}`, rating === null ? "DELETE" : "PUT", rating === null ? undefined : { rating }) as EpisodeRating;
    if (!data || !Number.isSafeInteger(data.count) || data.count < 0 || (data.average !== null && (!Number.isFinite(data.average) || data.average < 1 || data.average > 10)) || (data.my_rating !== null && (!Number.isInteger(data.my_rating) || data.my_rating < 1 || data.my_rating > 10))) throw new Error("Invalid rating response");
    return { data };
  } catch (error) {
    const signIn = error instanceof BackendError && error.status === 401;
    return { signIn, error: signIn ? "Please sign in to rate this episode." : "Couldn’t save your rating. Please try again." };
  }
}
