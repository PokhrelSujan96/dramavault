"use client";

import Link from "next/link";
import { useState } from "react";
import type { SeriesDetails } from "@/domain/models";
import styles from "./player.module.css";

export function EpisodeSelector({ series, currentId }: { series: SeriesDetails; currentId: string }) {
  const index = series.episodes.findIndex((episode) => episode.episode_id === currentId);
  const [range, setRange] = useState(Math.floor(Math.max(0, index) / 25));
  const groups = Math.ceil(series.episodes.length / 25);
  return <><div className={styles.episodeHead}><div>{Array.from({ length: groups }, (_, i) => <button key={i} className={range === i ? styles.rangeActive : ""} onClick={() => setRange(i)}>{i * 25 + 1}–{Math.min((i + 1) * 25, series.episodes.length)}</button>)}</div></div><div className={styles.episodes}>{series.episodes.slice(range * 25, range * 25 + 25).map((episode) => <Link key={episode.episode_id} className={episode.episode_id === currentId ? styles.current : ""} href={`/watch/${series.series_id}/${episode.episode_id}`} aria-label={`Episode ${episode.episode_number}${episode.locked ? ", locked" : ""}`}>{episode.episode_number}{episode.locked && <small>●</small>}</Link>)}</div></>;
}
