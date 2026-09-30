"use server";

import { authenticatedRequest, BackendError } from "@/infrastructure/api/authenticated";
import type { PlayerResult } from "@/domain/player/contracts";

export async function checkCommentAccess(): Promise<PlayerResult<null>> {
  try {
    await authenticatedRequest("/profile/me");
    return { data: null };
  } catch (error) {
    const signIn = error instanceof BackendError && error.status === 401;
    return { signIn, error: signIn ? "Please sign in again to view comments." : "Couldn’t open comments. Please try again." };
  }
}
