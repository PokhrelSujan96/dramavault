import Link from "next/link";
import type { HomeTitle } from "@/domain/home/title";
import { HomeArtwork } from "./home-artwork";
import { CardPreview } from "./card-preview";
import { TitleMeta } from "./title-meta";
import styles from "./cards.module.css";

export function TitleCard({ item, portrait = false, selected = false }: { item: HomeTitle; portrait?: boolean; selected?: boolean }) {
  return <article className={`${styles.card} ${portrait ? styles.portrait : styles.landscape} ${selected ? styles.selected : ""}`}>
    <CardPreview item={item}><Link href={`/watch/${encodeURIComponent(item.id)}`} aria-label={`Watch ${item.title}`}>
      <div className={styles.image}><HomeArtwork src={item.image} title={item.title} fill sizes="(max-width: 600px) 180px, (max-width: 1000px) 240px, 280px" /></div>
      <div className={styles.caption}><h3 title={item.title}>{item.title}</h3><TitleMeta item={item} /></div>
    </Link></CardPreview>
  </article>;
}
