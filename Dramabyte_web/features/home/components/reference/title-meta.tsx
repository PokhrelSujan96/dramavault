import { Film } from "lucide-react";
import type { HomeTitle } from "@/domain/home/title";
import styles from "./cards.module.css";

export function TitleMeta({ item, full = false }: { item: HomeTitle; full?: boolean }) {
  return <div className={styles.meta}><Film size={12} /><span>{item.episodeCount} {item.episodeCount === 1 ? "episode" : "episodes"}</span><span className={styles.secondary}>{item.genre}{full && item.freeEpisodeCount != null ? ` · ${item.freeEpisodeCount} free` : ""}</span></div>;
}
