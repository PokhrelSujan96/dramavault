import Link from "next/link";
import { Play, Star } from "lucide-react";
import { HomeFeed } from "@/domain/models";
import { SeriesRail } from "@/features/catalog/components/series-rail";
import { Hero } from "./hero";
import styles from "./home-experience.module.css";

function LandscapeRail({title,items}:{title:string;items:HomeFeed["trending"]}) {
  return <section className={styles.landscape}><div className="section-head"><h2 className="section-title">{title}</h2><span>View all</span></div><div>{items.map((item,index)=><Link href={`/watch/${item.series_id}`} key={`${title}-${item.series_id}-${index}`}><span className={styles.landscapeArt} style={item.thumbnail_url?{backgroundImage:`linear-gradient(0deg,#09090c,transparent 60%),url(${JSON.stringify(item.thumbnail_url)})`}:undefined}/><b>{item.title}</b><small><Star size={10} fill="currentColor"/> {item.genre}</small></Link>)}</div></section>;
}

export function HomeExperience({feed}:{feed:HomeFeed}) {
  const featured = feed.featured[0] ?? feed.trending[0];
  const spotlight = feed.featured[1] ?? feed.trending[1] ?? featured;
  const highlights = [...feed.featured, ...feed.trending].filter(
    (item,index,items) => items.findIndex((candidate) => candidate.series_id === item.series_id) === index,
  );
  if (!featured) return <main className={styles.canvas}><div className="container page-shell"><div className="empty">No published series are available yet.</div></div></main>;
  return <main className={styles.canvas}><Hero feature={featured} highlights={highlights}/><div className={styles.body}><SeriesRail title="Just released" items={feed.trending}/>{spotlight&&<section className={styles.spotlight} style={spotlight.thumbnail_url?{backgroundImage:`linear-gradient(90deg,#09090c 8%,rgba(9,9,12,.92) 39%,rgba(9,9,12,.16)),url(${JSON.stringify(spotlight.thumbnail_url)})`}:undefined}><div><span>Featured in Dramabyte</span><h2>{spotlight.title}</h2><p>{spotlight.description}</p><div className={styles.spotActions}><Link className="button button-red" href={`/watch/${spotlight.series_id}`}><Play size={15} fill="currentColor"/> Play now</Link><span><Star size={14} fill="currentColor"/> {spotlight.genre}</span></div></div></section>}<section className={styles.popular}><div className="section-head"><h2 className="section-title">Popular this week</h2></div><div>{feed.trending.slice(0,4).map((item,index)=><Link key={item.series_id} href={`/watch/${item.series_id}`}><strong>{index+1}</strong><span className={styles.thumb} style={item.thumbnail_url?{backgroundImage:`url(${JSON.stringify(item.thumbnail_url)})`}:undefined}/><span><b>{item.title}</b><small><Star size={10} fill="currentColor"/> {item.genre}</small></span></Link>)}</div></section><LandscapeRail title="Series" items={feed.trending}/>{feed.genres.map((rail)=><LandscapeRail key={rail.genre} title={rail.genre} items={rail.items}/>)}<section className={styles.genreBanner} style={featured.thumbnail_url?{backgroundImage:`linear-gradient(90deg,#09090c 8%,rgba(9,9,12,.72),transparent),url(${JSON.stringify(featured.thumbnail_url)})`}:undefined}><span>Explore by genre</span><h2>{featured.title}</h2><p>{featured.description}</p><Link className="button button-red" href={`/watch/${featured.series_id}`}><Play size={15} fill="currentColor"/> Play now</Link><div>{feed.genres.map((rail)=><span key={rail.genre}>{rail.genre}</span>)}</div></section></div></main>;
}
