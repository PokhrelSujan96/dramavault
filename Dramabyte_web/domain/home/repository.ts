import type { HomeFeed } from "@/domain/models";

export type HomeFeedResult = { feed: HomeFeed; unavailable: boolean };
export interface HomeRepository {
  feed(): Promise<HomeFeedResult>;
}
