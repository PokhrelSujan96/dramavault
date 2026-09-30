import Link from "next/link";
import { Play, Sparkles } from "lucide-react";
import { SeriesCard } from "@/domain/models";
import styles from "./hero.module.css";

export function Hero({feature,highlights}:{feature:SeriesCard;highlights:SeriesCard[]}) {
  const image = feature.thumbnail_url ? {backgroundImage:`url(${JSON.stringify(feature.thumbnail_url)})`} : undefined;
  const episodeLabel = `${feature.episode_count} episode${feature.episode_count===1?"":"s"}`;
  return <section className={styles.hero}><div className={styles.backdrop} style={image}/><div className={styles.art} style={image}><div className={styles.type}>DRAMA<br/>BYTE</div></div><div className={`container ${styles.content}`}><span className="pill"><Sparkles size={13}/> Dramabyte original</span><h1>{feature.title}</h1><p>{feature.description}</p><div className={styles.meta}><span>{feature.genre}</span><span>{episodeLabel}</span></div><div className={styles.actions}><Link className="button button-primary" href={`/watch/${feature.series_id}`}><Play size={18} fill="currentColor"/> Play</Link></div><div className={styles.selector}>{highlights.slice(0,5).map((item,index)=><Link key={item.series_id} className={index===0?styles.selected:""} href={`/watch/${item.series_id}`} aria-label={item.title} style={item.thumbnail_url?{backgroundImage:`url(${JSON.stringify(item.thumbnail_url)})`}:undefined}/>)}</div></div></section>;
}
