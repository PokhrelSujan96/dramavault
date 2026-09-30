"use server";

import { revalidatePath } from "next/cache";
import { updateWatchlist } from "@/application/home/watchlist";
import { libraryRepository } from "@/infrastructure/home/library-repository";

export async function setWatchlist(id: string, saved: boolean) {
  const result = await updateWatchlist(libraryRepository, id, saved);
  if (!result.error) {
    revalidatePath("/");
    revalidatePath("/library");
  }
  return result;
}
