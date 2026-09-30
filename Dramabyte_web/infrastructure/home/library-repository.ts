import "server-only";
import { cookies } from "next/headers";
import { backendUrl } from "@/infrastructure/api/backend";
import type { LibraryRepository } from "@/domain/home/library-repository";
import { readJson } from "@/infrastructure/api/read-json";
import { parseSeries } from "./validate-feed";

export async function getSavedSeries() {
  const token = (await cookies()).get("dramabyte_access")?.value;
  if (!token) return [];
  try {
    const response = await fetch(backendUrl("/library"), {
      headers: { Authorization: `Bearer ${token}` }, cache: "no-store",
      signal: AbortSignal.timeout(8000), redirect: "error",
    });
    if (!response.ok) { await response.body?.cancel(); return []; }
    return parseSeries(await readJson(response), 200);
  } catch {
    return [];
  }
}

async function updateSavedSeries(id: string, saved: boolean) {
  const token = (await cookies()).get("dramabyte_access")?.value;
  if (!token) return { error: "Sign in to save series.", signIn: true };
  try {
    const response = await fetch(backendUrl(`/library/${encodeURIComponent(id)}`), {
      method: saved ? "PUT" : "DELETE", headers: { Authorization: `Bearer ${token}` },
      cache: "no-store", signal: AbortSignal.timeout(8000), redirect: "error",
    });
    await response.body?.cancel();
    if (response.status === 401) return { error: "Please sign in again.", signIn: true };
    if (!response.ok) return { error: "Could not update your watchlist. Please try again.", signIn: false };
    return { error: null, signIn: false };
  } catch {
    return { error: "Could not reach your watchlist. Please try again.", signIn: false };
  }
}

export const libraryRepository: LibraryRepository = { setSaved: updateSavedSeries };
