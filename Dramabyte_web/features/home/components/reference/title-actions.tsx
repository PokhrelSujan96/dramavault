"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { Bookmark, Check, CirclePlay } from "lucide-react";
import { useState, useTransition } from "react";
import type { HomeTitle } from "@/domain/home/title";
import { setWatchlist } from "@/features/home/actions/watchlist";
import { useAccountCache } from "@/features/account/components/account-cache-provider";
import styles from "./hero.module.css";

export function TitleActions({ item, compact = false }: { item: HomeTitle; compact?: boolean }) {
  const router = useRouter();
  const cache = useAccountCache();
  const [saved, setSaved] = useState(item.saved);
  const [error, setError] = useState<string | null>(null);
  const [pending, startTransition] = useTransition();
  const toggle = () => {
    const nextSaved = !saved;
    const change = cache.editLibrary({ series_id: item.id, title: item.title, genre: item.genre, description: item.description, thumbnail_url: item.image, episode_count: item.episodeCount, free_episode_count: item.freeEpisodeCount }, nextSaved);
    setSaved(nextSaved);
    setError(null);
    startTransition(async () => {
      try {
        const result = await setWatchlist(item.id, nextSaved);
        if (result.signIn) {
          change.rollback(); setSaved(!nextSaved); cache.clear();
          router.push(`/signin?returnTo=${encodeURIComponent("/")}`);
          return;
        }
        if (result.error) { change.rollback(); setSaved(!nextSaved); setError(result.error); }
        else { change.commit(); router.refresh(); }
      } catch {
        change.rollback(); setSaved(!nextSaved);
        setError("Could not update your watchlist. Please try again.");
      }
    });
  };
  return <>
    <div className={`${styles.actions} ${compact ? styles.compactActions : ""}`}>
      <Link className={styles.play} aria-label={`Play ${item.title}`} href={`/watch/${encodeURIComponent(item.id)}`}><CirclePlay size={17} fill="white" stroke="#009b70" />{!compact && "Play Now"}</Link>
      <button className={styles.save} onClick={toggle} disabled={pending} aria-label={saved ? "Remove from watchlist" : "Add to watchlist"} aria-pressed={saved}>{saved ? <Check size={16} /> : <Bookmark size={16} />}{!compact && (saved ? "Added to Watchlist" : "Add Watchlist")}</button>
    </div>
    {error && <p className={styles.actionError} role="status">{error}</p>}
  </>;
}
