import Link from "next/link";
import type { HomeTitle } from "@/domain/home/title";
import { HomeArtwork } from "./home-artwork";
import { TitleMeta } from "./title-meta";
import styles from "./cards.module.css";

export function PopularRail({ items }: { items: HomeTitle[] }) {
  return <section className={styles.section} id="popular"><div className={styles.heading}><h2>Trending now</h2></div><div className={styles.popular}>{items.map((item, index) => <Link href={`/watch/${encodeURIComponent(item.id)}`} key={item.id} className={styles.ranked}><span className={styles.rank}>{index + 1}</span><div className={styles.rankedArt}><HomeArtwork src={item.image} title={item.title} fill sizes="76px" /></div><div><span className={styles.age}>Dramabyte Original</span><h3>{item.title}</h3><p>{item.genre}</p><TitleMeta item={item} /></div></Link>)}</div></section>;
}
