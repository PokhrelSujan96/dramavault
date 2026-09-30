"use client";

import { useEffect, useRef, useState } from "react";
import { Pause, Play, RotateCcw } from "lucide-react";
import type { PlaylistItem } from "@/domain/models";
import { createViewTracker } from "@/application/player/view-tracker";
import { recordPlaybackView } from "../actions/views";
import { refreshPlayback } from "../actions/engagement";
import styles from "./player.module.css";
import { Shimmer } from "@/components/loading/shimmer";
import { VideoControls } from "./video-controls";

export function VideoSurface({ current }: { current: PlaylistItem }) {
  const [views] = useState(() => createViewTracker((event) => recordPlaybackView(current.episode_id, event), () => crypto.randomUUID()));
  const video = useRef<HTMLVideoElement>(null);
  const frame = useRef<HTMLDivElement>(null);
  const mounted = useRef(false);
  const [source, setSource] = useState(current.video_url);
  const [ready, setReady] = useState(false);
  const [playing, setPlaying] = useState(false);
  const [error, setError] = useState<string | null>(current.video_url ? null : "This video isn’t available yet.");
  const [retrying, setRetrying] = useState(false);
  useEffect(() => {
    mounted.current = true;
    const element = video.current;
    if (element && current.video_url) { element.src = current.video_url; element.load(); }
    return () => { mounted.current = false; element?.pause(); element?.removeAttribute("src"); element?.load(); };
  }, [current.video_url]);
  const toggle = async () => {
    const element = video.current;
    if (!element) return;
    if (!element.paused) { element.pause(); return; }
    try { await element.play(); if (mounted.current) setError(null); }
    catch { if (mounted.current) setError("Tap play to start, or retry if the video is unavailable."); }
  };
  const retry = async () => {
    setRetrying(true);
    try {
      const result = await refreshPlayback(current.series_id, current.episode_id);
      if (!mounted.current) return;
      if (result.error) { setError(result.error); return; }
      setReady(false); setSource(result.data!); setError(null);
      if (video.current) { video.current.src = result.data!; video.current.load(); await video.current.play().catch(() => {}); }
    } catch { if (mounted.current) setError("Couldn’t load this video. Please try again."); }
    finally { if (mounted.current) setRetrying(false); }
  };
  return <div ref={frame} className={styles.videoFrame} onContextMenu={(event) => event.preventDefault()}><video ref={video} src={source || undefined} poster={current.thumbnail_url || undefined} controlsList="nodownload noremoteplayback" disablePictureInPicture disableRemotePlayback draggable={false} autoPlay playsInline preload="metadata" onLoadedData={() => setReady(true)} onCanPlay={() => { setReady(true); setError(null); }} onPlay={() => { setPlaying(true); setError(null); }} onTimeUpdate={(event) => views.tick(performance.now(), !event.currentTarget.paused && !event.currentTarget.seeking && document.visibilityState === "visible")} onSeeking={() => views.tick(performance.now(), false)} onWaiting={() => views.tick(performance.now(), false)} onPause={() => { views.tick(performance.now(), false); setPlaying(false); }} onEnded={() => { setPlaying(false); views.reset(); }} onError={() => setError("This video couldn’t be played. Please retry.")} />{!ready && !error && <Shimmer className={styles.mediaLoading} />}{!error && <button className={`${styles.play} ${playing ? styles.pauseControl : ""}`} onClick={toggle} aria-label={playing ? "Pause video" : "Play video"}>{playing ? <Pause fill="currentColor" /> : <Play fill="currentColor" />}</button>}{!error && <VideoControls video={video} frame={frame} playing={playing} toggle={toggle} />}{error && <div className={styles.videoError} role="status"><p>{error}</p><button onClick={retry} disabled={retrying}><RotateCcw size={16} />{retrying ? "Retrying…" : "Retry video"}</button></div>}</div>;
}
