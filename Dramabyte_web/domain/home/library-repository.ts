export type WatchlistResult = { error: string | null; signIn: boolean };

export interface LibraryRepository {
  setSaved(id: string, saved: boolean): Promise<WatchlistResult>;
}
