import { apiRequest } from "./api-client";
import { loadQuery, snapshot } from "./query-cache";
import type { GenerationResult } from "./project-types";

export async function loadGeneration(id: string, force = false) {
  const key = `/generation/project/${id}`;
  const cached = snapshot<GenerationResult>(key);
  await loadQuery(key, () => apiRequest<GenerationResult>(key), force || Date.now() - (cached.updatedAt ?? 0) > 240000);
  const result = snapshot<GenerationResult>(key);
  if (result.error) throw new Error(result.error);
  if (!result.data) throw new Error("Video is unavailable");
  return result.data;
}
