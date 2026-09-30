import type { LibraryRepository, WatchlistResult } from "@/domain/home/library-repository";

export async function updateWatchlist(repository: LibraryRepository, id: string, saved: boolean): Promise<WatchlistResult> {
  if (typeof id !== "string" || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id) || typeof saved !== "boolean") {
    return { error: "Invalid series.", signIn: false };
  }
  return repository.setSaved(id, saved);
}
