"use client";

import { useState } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import type { HomeCatalog } from "@/domain/home/title";
import { TitleActions } from "./title-actions";
import { TitleMeta } from "./title-meta";
import styles from "./hero.module.css";

export function GenreSpotlight({ genres }: { genres: HomeCatalog["genres"] }) {
  const [activeGenre, setActiveGenre] = useState(genres[0]?.genre);
  const active = Math.max(0, genres.findIndex((rail) => rail.genre === activeGenre));
  const current = genres[active]?.items[0];
  if (!current) return null;
  const move = (direction: number) => setActiveGenre(genres[(active + direction + genres.length) % genres.length].genre);
  return <section className={styles.genre} style={current.image ? { backgroundImage: `url(${JSON.stringify(current.image)})` } : undefined}><div className={styles.genreCopy}><span className={styles.eyebrow}>Explore by genre</span><h2>{current.title}</h2><TitleMeta item={current} full /><TitleActions key={`${current.id}-${current.saved}`} item={current} /><div className={styles.genreArrows}><button aria-label="Previous genre" onClick={() => move(-1)}><ChevronLeft size={15} /></button><button aria-label="Next genre" onClick={() => move(1)}><ChevronRight size={15} /></button></div></div><div className={styles.genreTabs}>{genres.map((rail, index) => <button key={rail.genre} aria-pressed={active === index} className={active === index ? styles.activeGenre : ""} style={rail.items[0].image ? { backgroundImage: `linear-gradient(#0009,#0009),url(${JSON.stringify(rail.items[0].image)})` } : undefined} onClick={() => setActiveGenre(rail.genre)}>{rail.genre}</button>)}</div></section>;
}
