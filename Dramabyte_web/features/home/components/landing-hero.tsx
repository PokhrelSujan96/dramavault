"use client";

import Link from "next/link";
import { Bookmark, Play } from "lucide-react";
import { useEffect, useState } from "react";
import { SeriesCard } from "@/domain/models";
import styles from "./landing-hero.module.css";

export function LandingHero({ series }: { series: SeriesCard[] }) {
  const slides = series.slice(0, 5);
  const [active, setActive] = useState(0);

  useEffect(() => {
    if (slides.length < 2) return;
    const timer = window.setInterval(() => setActive((value) => (value + 1) % slides.length), 6500);
    return () => window.clearInterval(timer);
  }, [slides.length]);

  if (!slides.length) {
    return <section className={styles.empty}><h1>Stories are coming soon.</h1><p>Published Dramabyte series will appear here.</p></section>;
  }

  const current = slides[active];
  const image = current.thumbnail_url ? { backgroundImage: `url(${JSON.stringify(current.thumbnail_url)})` } : undefined;
  const episodes = `${current.episode_count} episode${current.episode_count === 1 ? "" : "s"}`;

  return <section className={styles.hero}>
    <div key={`${current.series_id}-blur`} className={styles.backdrop} style={image}/>
    <div key={current.series_id} className={styles.artwork} style={image}/>
    <div className={styles.shade}/>
    <div className={styles.content}>
      <span className={styles.badge}>Series</span>
      <h1>{current.title}</h1>
      <div className={styles.meta}><span>{episodes}</span><span>{current.genre}</span><span>Dramabyte Original</span></div>
      <p>{current.description}</p>
      <div className={styles.actions}>
        <Link href={`/watch/${current.series_id}`} className={styles.play}><Play size={15} fill="currentColor"/> Watch now</Link>
        <Link href="/library" className={styles.watchlist}><Bookmark size={15}/> Add watchlist</Link>
      </div>
    </div>
    <div className={styles.dots} aria-label="Featured series">
      {slides.map((item, index) => <button key={item.series_id} onClick={() => setActive(index)} className={index === active ? styles.active : ""} aria-label={`Show ${item.title}`}/>) }
    </div>
  </section>;
}
