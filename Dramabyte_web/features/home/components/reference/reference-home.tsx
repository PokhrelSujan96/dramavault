import type { HomeCatalog } from "@/domain/home/title";
import { HomeHero } from "./home-hero";
import { TitleRail } from "./title-rail";
import { PopularRail } from "./popular-rail";
import { HomeFooter } from "./home-footer";
import styles from "./home.module.css";

export function ReferenceHome({ catalog, unavailable }: { catalog: HomeCatalog; unavailable: boolean }) {
  const featured = catalog.featured.length ? catalog.featured : catalog.all;
  const trending = catalog.trending.length ? catalog.trending : catalog.all;
  return <main className={styles.home}>
    <div className={styles.opening}>{featured.length ? <HomeHero items={featured.slice(0, 5)} /> : <section className={styles.empty}><h1>{unavailable ? "We couldn’t load the series." : "New stories are on their way."}</h1><p>{unavailable ? "Please try again shortly." : "Published Dramabyte series will appear here."}</p></section>}</div>
    {!!catalog.all.length && <>
      <TitleRail title="Explore series" items={catalog.all} portrait />
      <PopularRail items={trending.slice(0, 6)} />
      <TitleRail title="Series" items={catalog.all} />
      {catalog.genres.map((rail) => <TitleRail key={rail.genre} title={rail.genre} items={rail.items} genre />)}
    </>}
    <HomeFooter />
  </main>;
}
