"use server";

import { cookies } from "next/headers";
import { publicRequest } from "@/infrastructure/api/public-request";
import { BackendError, authenticatedRequest } from "@/infrastructure/api/authenticated";
import { validId, type CommentPage, type EpisodeComment, type PlayerResult } from "@/domain/player/contracts";
import { parseComment, parseComments } from "@/infrastructure/player/validate-player";

function failure(error: unknown): { error: string; signIn?: boolean } {
  return { error: error instanceof BackendError && error.status === 401 ? "Please sign in again to continue." : error instanceof BackendError && error.status === 429 ? "Please wait a moment before trying again." : "Couldn’t update comments. Please try again.", signIn: error instanceof BackendError && error.status === 401 };
}
export async function listComments(id: string, sort: "top" | "new", cursor: string | null = null, replies = false): Promise<PlayerResult<CommentPage>> {
  if (!validId(id) || !["top", "new"].includes(sort) || typeof replies !== "boolean" || (cursor !== null && (typeof cursor !== "string" || cursor.length > 300))) return { error: "Invalid comments request." };
  const query = new URLSearchParams({ sort, limit: replies ? "10" : "20" });
  if (cursor) query.set("cursor", cursor);
  try {
    let signedIn = !!(await cookies()).get("dramabyte_access")?.value;
    const path = `/comments/${replies ? `${id}/replies` : `episodes/${id}`}?${query}`;
    let raw;
    try { raw = await (signedIn ? authenticatedRequest(path) : publicRequest(`/public${path}`)); }
    catch (error) {
      if (!signedIn || !(error instanceof BackendError) || error.status !== 401) throw error;
      signedIn = false;
      raw = await publicRequest(`/public${path}`);
    }
    const data = parseComments(raw);
    return { data: { ...data, can_post: signedIn } };
  }
  catch (error) { return failure(error); }
}
export async function postComment(id: string, body: string, key: string, parent: string | null = null): Promise<PlayerResult<EpisodeComment>> {
  if (!validId(id) || !validId(key) || (parent !== null && !validId(parent)) || typeof body !== "string" || !body.trim() || body.trim().length > 500) return { error: "Comments must be between 1 and 500 characters." };
  try { return { data: parseComment(await authenticatedRequest(`/comments/episodes/${id}`, "POST", { body: body.trim(), idempotency_key: key, parent_id: parent })) }; }
  catch (error) { return failure(error); }
}
export async function updateComment(id: string, action: "like" | "delete" | "report", value?: boolean | string): Promise<PlayerResult<number | null>> {
  if (!validId(id)) return { error: "Invalid comment." };
  try {
    if (action === "like" && typeof value === "boolean") {
      const result = await authenticatedRequest(`/comments/${id}/like`, "PUT", { liked: value }) as { like_count?: unknown };
      if (typeof result?.like_count !== "number" || !Number.isSafeInteger(result.like_count) || result.like_count < 0) throw new Error("Invalid like count");
      return { data: result.like_count };
    }
    if (action === "delete") { await authenticatedRequest(`/comments/${id}`, "DELETE"); return { data: null }; }
    if (action === "report" && typeof value === "string" && value.trim().length > 0 && value.length <= 200) { await authenticatedRequest(`/comments/${id}/report`, "POST", { reason: value }); return { data: null }; }
    return { error: "Invalid comment action." };
  } catch (error) { return failure(error); }
}
