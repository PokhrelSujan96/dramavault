"use client";

import { Share2 } from "lucide-react";
import { useState } from "react";

export function ShareButton({ title, seriesId, episodeId }: { title: string; seriesId: string; episodeId: string }) {
  const [status, setStatus] = useState("");
  const share = async () => {
    const url = new URL(`/watch/${seriesId}/${episodeId}`, window.location.origin).href;
    try {
      if (navigator.share) { await navigator.share({ title, url }); setStatus("Shared"); }
      else { await navigator.clipboard.writeText(url); setStatus("Link copied"); }
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") return;
      try { await navigator.clipboard.writeText(url); setStatus("Link copied"); }
      catch { setStatus("Couldn’t share. Copy the link from your address bar."); }
    }
  };
  return <button onClick={share} aria-label="Share episode"><Share2 /><span aria-live="polite">{status || "Share"}</span></button>;
}
