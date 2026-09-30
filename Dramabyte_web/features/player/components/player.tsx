"use client";

import Link from "next/link";
import { useCallback, useId, useState } from "react";
import { CommentsSidebar } from "./comments-sidebar";
import { ArrowLeft } from "lucide-react";
import type { PlaylistItem, SeriesDetails } from "@/domain/models";
import { VideoSurface } from "./video-surface";
import { EngagementControls } from "./engagement-controls";
import { RatingSummary } from "./rating-summary";
import { EpisodeSelector } from "./episode-selector";
import styles from "./player.module.css";

export function Player({ series, current }: { series: SeriesDetails; current: PlaylistItem }) {
  const [comments, setComments] = useState(current.comments ?? 0);
  const panelId = useId();
  const onCount = useCallback((delta: number) => setComments((value) => Math.max(0, value + delta)), []);
  return <main className={`${styles.page} ${styles.withComments}`}><Link className={styles.back} href="/" aria-label="Back to home"><ArrowLeft /></Link><section className={styles.stage}><VideoSurface current={current} /></section><aside className={styles.details}><div className={styles.breadcrumbs}>Home / {series.title} / Episode {current.episode_number}</div><h1>Episode {current.episode_number} · {current.title || series.title}</h1><h2>Plot of Episode {current.episode_number}</h2><p>{current.description || series.description}</p><div className={styles.tags}><span>{series.genre}</span><span>Original</span></div><RatingSummary series={series} /><EngagementControls current={current} /><EpisodeSelector series={series} currentId={current.episode_id} /></aside><CommentsSidebar count={comments} id={panelId} episodeId={current.episode_id} onCount={onCount} /></main>;
}
