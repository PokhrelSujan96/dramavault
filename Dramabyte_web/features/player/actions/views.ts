"use server";

import { cookies } from "next/headers";
import { validId } from "@/domain/player/contracts";
import { authenticatedRequest } from "@/infrastructure/api/authenticated";
import { publicRequest } from "@/infrastructure/api/public-request";

export async function recordPlaybackView(episodeId: string, eventId: string): Promise<boolean> {
  if (!validId(episodeId) || !validId(eventId)) return false;
  try {
    if ((await cookies()).get("dramabyte_access")?.value) {
      await authenticatedRequest("/views/batch", "POST", { batch_id: eventId, items: [{ episode_id: episodeId, count: 1 }] });
    } else {
      await publicRequest("/public/views", "POST", { episode_id: episodeId, event_id: eventId });
    }
    return true;
  } catch { return false; }
}
