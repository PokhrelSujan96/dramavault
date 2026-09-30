"use client";

import { Star } from "lucide-react";
import { useEffect, useId, useRef, useState } from "react";
import type { PlaylistItem } from "@/domain/models";
import { rateEpisode } from "../actions/rating";
import { ActionTooltip } from "./action-tooltip";
import styles from "./episode-rating.module.css";

export function EpisodeRating({ current }: { current: PlaylistItem }) {
  const [mine, setMine] = useState(current.my_rating ?? null);
  const [open, setOpen] = useState(false);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const root = useRef<HTMLDivElement>(null);
  const mounted = useRef(false);
  const busy = useRef(false);
  const id = useId();
  useEffect(() => { mounted.current = true; return () => { mounted.current = false; }; }, []);
  useEffect(() => {
    if (!open) return;
    const outside = (event: PointerEvent) => { if (!root.current?.contains(event.target as Node)) setOpen(false); };
    document.addEventListener("pointerdown", outside);
    return () => document.removeEventListener("pointerdown", outside);
  }, [open]);
  const save = async (rating: number | null) => {
    if (busy.current) return;
    busy.current = true;
    const previous = mine;
    setMine(rating); setOpen(false); setPending(true); setError(null);
    try {
      const result = await rateEpisode(current.episode_id, rating);
      if (!mounted.current) return;
      if (result.error) { setMine(previous); setError(result.error); setOpen(false); }
      else { setMine(result.data!.my_rating); setOpen(false); }
    } catch { if (mounted.current) { setMine(previous); setError("Couldn’t save your rating."); } }
    finally { busy.current = false; if (mounted.current) setPending(false); }
  };
  return <div ref={root} className={styles.root} onKeyDown={(event) => { if (event.key === "Escape") { setOpen(false); root.current?.querySelector<HTMLButtonElement>("button")?.focus(); } }}><button type="button" onClick={() => setOpen(!open)} aria-expanded={open} aria-controls={id} aria-describedby={error ? `${id}-error` : undefined}><Star fill={mine ? "currentColor" : "none"} /><span>{mine ? `${mine}/10` : "Rate"}</span></button><ActionTooltip key={error ?? "none"} id={`${id}-error`} message={error} />{open && <div id={id} className={styles.panel}><h3>Rate this episode</h3><p>Choose a score from 1 to 10</p><div className={styles.scores}>{Array.from({ length: 10 }, (_, index) => index + 1).map((score) => <button type="button" key={score} disabled={pending} aria-pressed={mine === score} onClick={() => void save(score)}>{score}</button>)}</div>{mine !== null && <button type="button" disabled={pending} onClick={() => void save(null)}>Remove rating</button>}</div>}</div>;
}
