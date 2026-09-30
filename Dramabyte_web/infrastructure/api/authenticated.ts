import "server-only";
import { cookies } from "next/headers";
import { backendUrl } from "./backend";
import { readJson } from "./read-json";

export class BackendError extends Error {
  constructor(public status: number) { super("Backend request failed"); }
}
export async function authenticatedRequest(path: string, method = "GET", body?: unknown) {
  const token = (await cookies()).get("dramabyte_access")?.value;
  if (!token) throw new BackendError(401);
  const response = await fetch(backendUrl(path), {
    method, headers: { Authorization: `Bearer ${token}`, ...(body !== undefined ? { "Content-Type": "application/json" } : {}) },
    body: body !== undefined ? JSON.stringify(body) : undefined,
    cache: "no-store", redirect: "error", signal: AbortSignal.timeout(8000),
  });
  if (!response.ok) { await response.body?.cancel(); throw new BackendError(response.status); }
  if (response.status === 204) { await response.body?.cancel(); return null; }
  return readJson(response);
}
