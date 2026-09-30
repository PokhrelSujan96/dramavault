import type { HomeTitle } from "@/domain/home/title";
import { CompactList } from "./compact-list";
import styles from "./cards.module.css";

export function AwardsSection({ featured, trending }: { featured: HomeTitle[]; trending: HomeTitle[] }) {
  return <section className={styles.awards}><CompactList heading="Featured" items={featured.slice(0, 4)} /><CompactList heading="Trending" items={trending.slice(0, 4)} /></section>;
}
