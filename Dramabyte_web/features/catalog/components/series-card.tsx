import Link from "next/link";
import { Play } from "lucide-react";
import { SeriesCard as Series } from "@/domain/models";
import styles from "./series-card.module.css";

export function SeriesCard({ item, index = 0 }: { item: Series; index?: number }) {
  return <Link href={`/watch/${item.series_id}`} className={styles.card}><div className={`${styles.poster} ${styles[`tone${index % 6}`]}`} style={item.thumbnail_url ? { backgroundImage: `linear-gradient(0deg,rgba(4,4,6,.92),transparent 65%),url(${item.thumbnail_url})` } : undefined}><div className={styles.monogram}>{item.title.split(" ").slice(0,2).map((word)=>word[0]).join("")}</div><span className={styles.badge}><Play size={11} fill="currentColor"/> {item.episode_count} eps</span></div><h3>{item.title}</h3><p>{item.genre} · Series</p></Link>;
}
