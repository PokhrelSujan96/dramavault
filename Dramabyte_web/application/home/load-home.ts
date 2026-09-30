import type { HomeRepository } from "@/domain/home/repository";
import { createHomeCatalog } from "./catalog";

export async function loadHome(repository: HomeRepository, savedIds: Promise<string[]>) {
  const [result, saved] = await Promise.all([repository.feed(), savedIds]);
  return { catalog: createHomeCatalog(result.feed, saved), unavailable: result.unavailable };
}
