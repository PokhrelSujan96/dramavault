import "server-only";
import type { HomeRepository } from "@/domain/home/repository";
import { backendUrl } from "@/infrastructure/api/backend";
import { readJson } from "@/infrastructure/api/read-json";
import { parseHomeFeed } from "./validate-feed";

export const homeRepository: HomeRepository = {
  async feed() {
    try {
      const response = await fetch(backendUrl("/home"), {
        next: { revalidate: 60 }, signal: AbortSignal.timeout(8000), redirect: "error",
      });
      if (!response.ok) {
        await response.body?.cancel();
        throw new Error("Home feed unavailable");
      }
      return { feed: parseHomeFeed(await readJson(response)), unavailable: false };
    } catch {
      return { feed: { featured: [], trending: [], genres: [] }, unavailable: true };
    }
  },
};
