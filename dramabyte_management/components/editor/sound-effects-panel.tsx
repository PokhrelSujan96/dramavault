"use client";

import { useEffect, useRef, useState } from "react";
import { apiRequest } from "@/lib/api-client";
import type { SoundEffect } from "@/components/editor/editor-types";

type Track = {
  id: string;
  title: string;
  creator: string;
  source_url: string;
  audio_url: string;
  license: "cc0" | "by";
  license_version: string;
  license_url: string;
  attribution: string;
  duration: number;
};
type Results = { page: number; page_count: number; result_count: number; results: Track[] };
type Props = {
  value: SoundEffect[];
  onChange: (items: SoundEffect[]) => void;
  currentTime: number;
};

export function SoundEffectsPanel({ value, onChange, currentTime }: Props) {
  const [query, setQuery] = useState("");
  const [submitted, setSubmitted] = useState("");
  const [searchVersion, setSearchVersion] = useState(0);
  const [page, setPage] = useState(1);
  const [results, setResults] = useState<Results>();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [preview, setPreview] = useState("");
  const player = useRef<HTMLAudioElement>(null);

  useEffect(() => {
    if (!submitted) return;
    let active = true;
    void apiRequest<Results>(`/generation/sound-effects/search?q=${encodeURIComponent(submitted)}&page=${page}`)
      .then((data) => { if (active) setResults(data); })
      .catch((reason: Error) => { if (active) setError(reason.message); })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, [submitted, page, searchVersion]);

  const search = (event: React.FormEvent) => {
    event.preventDefault();
    if (query.trim().length < 2) return;
    setPage(1);
    setLoading(true);
    setError("");
    setSubmitted(query.trim());
    setSearchVersion((version) => version + 1);
  };
  const togglePreview = (track: Track) => {
    if (preview === track.id) {
      player.current?.pause();
      setPreview("");
      return;
    }
    if (!player.current) return;
    player.current.src = track.audio_url;
    player.current.volume = 0.8;
    void player.current.play().catch(() => setError("Preview unavailable for this sound."));
    setPreview(track.id);
  };
  const add = (track: Track) => {
    if (value.some((item) => item.track_id === track.id)) return;
    onChange([...value, {
      track_id: track.id,
      title: track.title,
      creator: track.creator,
      source_url: track.source_url,
      audio_url: track.audio_url,
      license: track.license,
      license_version: track.license_version,
      license_url: track.license_url,
      attribution: track.attribution,
      duration: track.duration,
      start: currentTime,
      trim_start: 0,
      trim_end: Math.min(track.duration || 5, 5),
      volume: 0.8,
      fade_in: 0,
      fade_out: 0,
    }]);
  };

  return <aside className="sound-effects-panel">
    <div className="editor-panel-title"><h2>Sound effects</h2></div>
    <div className="sound-effects-content">
      <p>Search Openverse audio under CC0 or CC BY licenses. Credit BY creators on export.</p>
      <form onSubmit={search}><input aria-label="Search sound effects" minLength={2} onChange={(event) => setQuery(event.target.value)} placeholder="rain, footsteps, door…" value={query} /><button disabled={query.trim().length < 2} type="submit">Search</button></form>
      {loading ? <p role="status">Searching sound effects…</p> : null}
      {error ? <p className="editor-error" role="alert">{error}</p> : null}
      <div className="sound-effects-results">{results?.results.map((track) => <article key={track.id}>
        <strong>{track.title}</strong><small>{track.creator} · CC {track.license.toUpperCase()}</small>
        <div><button onClick={() => togglePreview(track)} type="button">{preview === track.id ? "Pause" : "Preview"}</button><button disabled={value.some((item) => item.track_id === track.id)} onClick={() => add(track)} type="button">{value.some((item) => item.track_id === track.id) ? "Added" : "Add to timeline"}</button></div>
        <a href={track.source_url} rel="noreferrer" target="_blank">Source and license</a>
      </article>)}</div>
      {!loading && results && results.results.length === 0 ? <p className="sound-effects-empty">No matching openly licensed effects. Try a broader search such as “rain”, “footsteps”, or “door”.</p> : null}
      {results?.page_count && results.page_count > 1 ? <nav className="music-pagination">
        <button disabled={page <= 1 || loading} onClick={() => { setLoading(true); setPage((number) => number - 1); }} type="button">Previous</button><span>{page} / {results.page_count}</span><button disabled={page >= results.page_count || loading} onClick={() => { setLoading(true); setPage((number) => number + 1); }} type="button">Next</button>
      </nav> : null}
      <section className="sound-effects-selected"><h3>Timeline clips · {value.length}</h3>
        {value.map((effect, index) => <div className="effect-properties" key={effect.track_id}>
          <strong>{effect.title}</strong><button onClick={() => onChange(value.filter((_, itemIndex) => itemIndex !== index))} type="button">Remove</button>
          <label>Start <input max="3600" min="0" onChange={(event) => update(index, "start", Number(event.target.value))} step="0.1" type="number" value={effect.start} /></label>
          <label>Trim in <input max={effect.duration} min="0" onChange={(event) => update(index, "trim_start", Number(event.target.value))} step="0.1" type="number" value={effect.trim_start} /></label>
          <label>Trim out <input max={effect.duration || 3600} min="0.1" onChange={(event) => update(index, "trim_end", Number(event.target.value))} step="0.1" type="number" value={effect.trim_end} /></label>
          <label>Volume <input max="1" min="0" onChange={(event) => update(index, "volume", Number(event.target.value))} step="0.01" type="range" value={effect.volume} /></label>
          <label>Fade in <input max="10" min="0" onChange={(event) => update(index, "fade_in", Number(event.target.value))} step="0.1" type="number" value={effect.fade_in} /></label>
          <label>Fade out <input max="10" min="0" onChange={(event) => update(index, "fade_out", Number(event.target.value))} step="0.1" type="number" value={effect.fade_out} /></label>
          <a href={effect.source_url} rel="noreferrer" target="_blank">License and source</a>
        </div>)}
      </section>
      <audio onEnded={() => setPreview("")} onError={() => setError("This sound could not be previewed.")} ref={player} />
      <small className="openverse-credit">Openverse sound library · openverse.org</small>
    </div>
  </aside>;

  function update(index: number, key: keyof SoundEffect, amount: number) {
    onChange(value.map((item, itemIndex) => {
      if (itemIndex !== index) return item;
      if (key === "trim_start") {
        return { ...item, trim_start: clamp(amount, 0, item.trim_end - .1) };
      }
      if (key === "trim_end") {
        return { ...item, trim_end: clamp(amount, item.trim_start + .1, item.duration || 3600) };
      }
      if (key === "start") return { ...item, start: clamp(amount, 0, 3600) };
      if (key === "volume") return { ...item, volume: clamp(amount, 0, 1) };
      if (key === "fade_in" || key === "fade_out") {
        return { ...item, [key]: clamp(amount, 0, 30) };
      }
      return item;
    }));
  }
}

function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(max, value));
}
