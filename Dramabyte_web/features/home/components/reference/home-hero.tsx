"use client";

import { useState } from "react";
import type { HomeTitle } from "@/domain/home/title";
import { HomeArtwork } from "./home-artwork";
import { TitleActions } from "./title-actions";
import { TitleMeta } from "./title-meta";
import styles from "./hero.module.css";

export function HomeHero({ items }: { items: HomeTitle[] }) {
  const [activeId, setActiveId] = useState(items[0]?.id);
  const current = items.find((item) => item.id === activeId) ?? items[0];
  if (!current) return null;
  return <section className={`${styles.hero} ${styles.carousel}`} id="home" aria-label="Featured stories" aria-roledescription="carousel">
    {items.map((item) => <div key={item.id} className={`${styles.heroSlide} ${item.id === current.id ? styles.visibleSlide : ""}`} inert={item.id !== current.id} aria-hidden={item.id !== current.id} style={item.image ? { backgroundImage: `url(${JSON.stringify(item.image)})` } : undefined}>
      {item.image && <div className={styles.mobileArtwork}><HomeArtwork src={item.image} title={item.title} width={1200} height={1800} sizes="100vw" /></div>}
      <div className={styles.heroContent}><span className={styles.badge}>Dramabyte Original</span><h1>{item.title}</h1><TitleMeta item={item} full /><p className={styles.description}>{item.description}</p><TitleActions item={item} /></div>
    </div>)}
    <div className={styles.dots} aria-label="Featured series">{items.map((slide) => <button type="button" key={slide.id} onClick={() => setActiveId(slide.id)} aria-label={`Show ${slide.title}`} aria-pressed={slide.id === current.id} className={slide.id === current.id ? styles.activeDot : ""} />)}</div>
  </section>;
}
