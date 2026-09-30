import "server-only";
import { backendUrl } from "./backend";
import { readJson } from "./read-json";
import { BackendError } from "./authenticated";

export async function publicRequest(path: string, method = "GET", body?: unknown) {
  const response = await fetch(backendUrl(path), { method, ...(body !== undefined ? { headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) } : {}), cache: "no-store", redirect: "error", signal: AbortSignal.timeout(8000) });
  if (!response.ok) { await response.body?.cancel(); throw new BackendError(response.status); }
  if (response.status === 204) { await response.body?.cancel(); return null; }
  return readJson(response);
}
