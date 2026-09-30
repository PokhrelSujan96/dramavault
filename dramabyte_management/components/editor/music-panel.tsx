"use client";

import { useEffect, useRef, useState } from "react";
import { apiRequest } from "@/lib/api-client";
import type { BackgroundMusic } from "@/components/editor/editor-types";

type Track = Omit<BackgroundMusic, "volume" | "fade_in" | "fade_out" | "start" | "track_id"> & { id: string; category: string };
type SearchResult = { page: number; page_count: number; result_count: number; results: Track[] };
type Props = { projectId: string; value: BackgroundMusic | null; onChange: (value: BackgroundMusic | null) => void };

export function MusicPanel({ projectId, value, onChange }: Props) {
  const [query, setQuery] = useState("");
  const [submitted, setSubmitted] = useState("");
  const [page, setPage] = useState(1);
  const [results, setResults] = useState<SearchResult>();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [previewId, setPreviewId] = useState("");
  const player = useRef<HTMLAudioElement>(null);

  useEffect(() => {
    if (!submitted) return;
    let live = true;
    const timer = window.setTimeout(() => {
      setLoading(true);
      setError("");
      void apiRequest<SearchResult>(`/generation/music/search?q=${encodeURIComponent(submitted)}&page=${page}`)
        .then((result) => { if (live) setResults(result); })
        .catch((reason) => { if (live) setError(reason instanceof Error ? reason.message : "Music search failed"); })
        .finally(() => { if (live) setLoading(false); });
    }, 250);
    return () => { live = false; window.clearTimeout(timer); };
  }, [projectId, submitted, page]);

  const search = (event: React.FormEvent) => {
    event.preventDefault();
    const value = query.trim();
    if (value.length >= 2) { setPage(1); setSubmitted(value); }
  };
  const preview = (track: Track) => {
    if (previewId === track.id) {
      player.current?.pause();
      setPreviewId("");
    } else {
      if (player.current) {
        player.current.pause();
        player.current.src = track.audio_url;
        player.current.volume = .65;
        void player.current.play();
      }
      setPreviewId(track.id);
    }
  };
  const selectTrack = (track: Track) => {
    player.current?.pause();
    setPreviewId("");
    onChange({ ...track, track_id: track.id, volume: value?.volume ?? .18, fade_in: value?.fade_in ?? 1,
      fade_out: value?.fade_out ?? 2, start: value?.start ?? 0 });
  };
  const adjust = (field: "volume" | "fade_in" | "fade_out" | "start", amount: number) => {
    if (value) onChange({ ...value, [field]: amount });
  };

  return (
    <aside className="music-panel">
      <div className="editor-panel-title"><h2>Background music</h2>
        {value ? <button aria-label="Remove background music" onClick={() => onChange(null)} type="button">Remove</button> : null}
      </div>
      <div className="music-controls">
        <p>Browse Openverse tracks with CC0 or CC BY licenses.</p>
        <form onSubmit={search}><input aria-label="Search music" minLength={2} onChange={(event) => setQuery(event.target.value)} placeholder="Search cinematic, piano…" value={query} /><button disabled={query.trim().length < 2} type="submit">Search</button></form>
        {value ? <section className="music-selected">
          <strong>Selected track</strong><span>{value.title}</span><small>By {value.creator} · CC {value.license.toUpperCase()}</small>
          <a href={value.source_url} rel="noreferrer" target="_blank">View source and license</a>
          {value.attribution ? <small>{value.attribution}</small> : null}
          <label>Music volume <span>{Math.round(value.volume * 100)}%</span><input max="1" min="0" onChange={(event) => adjust("volume", Number(event.target.value))} step=".01" type="range" value={value.volume} /></label>
          <label>Fade in <span>{value.fade_in}s</span><input max="10" min="0" onChange={(event) => adjust("fade_in", Number(event.target.value))} step=".5" type="range" value={value.fade_in} /></label>
          <label>Fade out <span>{value.fade_out}s</span><input max="10" min="0" onChange={(event) => adjust("fade_out", Number(event.target.value))} step=".5" type="range" value={value.fade_out} /></label>
          <label>Start time <span>{value.start}s</span><input max="60" min="0" onChange={(event) => adjust("start", Number(event.target.value))} step=".5" type="range" value={value.start} /></label>
          <p>Creator and license details are included with export.</p>
        </section> : null}
        {loading ? <p role="status">Searching Openverse…</p> : null}
        {error ? <p className="audio-error" role="alert">{error}</p> : null}
        <div className="music-results">
          {results?.results.map((track) => <TrackResult key={track.id} track={track} isSelected={value?.track_id === track.id} isPreviewing={previewId === track.id} onPreview={() => preview(track)} onSelect={() => selectTrack(track)} />)}
        </div>
        {results && !results.results.length && !loading ? <p>No tracks found with the selected commercial friendly licenses. Try another search.</p> : null}
        {results && results.page_count > 1 ? <nav className="music-pagination" aria-label="Music search pages">
          <button disabled={page <= 1 || loading} onClick={() => setPage((value) => value - 1)} type="button">Previous</button>
          <span>{results.page} / {results.page_count}</span>
          <button disabled={page >= results.page_count || loading} onClick={() => setPage((value) => value + 1)} type="button">Next</button>
        </nav> : null}
        {!submitted ? <p>Search by mood, genre, instrument, or title.</p> : null}
        <audio onEnded={() => setPreviewId("")} onError={() => { setPreviewId(""); setError("This track could not be previewed. Open the track page to check availability."); }} ref={player} />
        <small className="openverse-credit">Audio search powered by <a href="https://openverse.org" rel="noreferrer" target="_blank">Openverse</a>.</small>
      </div>
    </aside>
  );
}

function TrackResult({ track, isSelected, isPreviewing, onPreview, onSelect }: { track: Track; isSelected: boolean; isPreviewing: boolean; onPreview: () => void; onSelect: () => void }) {
  return <article>
    <strong title={track.title}>{track.title}</strong><span>{track.creator}</span>
    <small>CC {track.license.toUpperCase()}{track.license_version ? ` ${track.license_version}` : ""} · {formatDuration(track.duration)}</small>
    <a href={track.source_url} rel="noreferrer" target="_blank">Track details</a>
    <div><button onClick={onPreview} type="button">{isPreviewing ? "Pause" : "Preview"}</button><button onClick={onSelect} type="button">{isSelected ? "Selected" : "Use track"}</button></div>
  </article>;
}

function formatDuration(seconds: number) {
  if (!seconds) return "duration unknown";
  return `${Math.floor(seconds / 60)}:${String(Math.floor(seconds % 60)).padStart(2, "0")}`;
}
