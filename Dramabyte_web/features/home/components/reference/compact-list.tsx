import Link from "next/link";
import type { HomeTitle } from "@/domain/home/title";
import { HomeArtwork } from "./home-artwork";
import { TitleMeta } from "./title-meta";
import styles from "./cards.module.css";

export function CompactList({ heading, items }: { heading: string; items: HomeTitle[] }) {
  return <section className={styles.compact}><div className={styles.heading}><h2>{heading}</h2></div>{items.map((item) => <Link href={`/watch/${encodeURIComponent(item.id)}`} className={styles.compactItem} key={item.id}><div className={styles.compactArt}><HomeArtwork src={item.image} title={item.title} fill sizes="78px" /></div><div><span className={styles.age}>Dramabyte Original</span><h3 title={item.title}>{item.title}</h3><p>{item.genre}</p><TitleMeta item={item} /></div></Link>)}</section>;
}
