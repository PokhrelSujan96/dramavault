import type { HomeTitle } from "@/domain/home/title";
import { TitleActions } from "./title-actions";
import { TitleMeta } from "./title-meta";
import { TitleCard } from "./title-card";
import styles from "./hero.module.css";

export function FeaturedSpotlight({ item, items }: { item: HomeTitle; items: HomeTitle[] }) {
  return <section className={styles.featured} style={item.image ? { backgroundImage: `url(${JSON.stringify(item.image)})` } : undefined}><div className={styles.featuredCopy}><h2>Featured in Dramabyte</h2><p className={styles.subtitle}>Stories selected for you</p><span className={styles.eyebrow}>{item.genre}</span><h3>{item.title}</h3><TitleMeta item={item} full /><p className={styles.description}>{item.description}</p><TitleActions key={`${item.id}-${item.saved}`} item={item} /></div><div className={styles.featuredRail}>{items.map((series) => <TitleCard key={series.id} item={series} portrait selected={series.id === item.id} />)}</div></section>;
}
