"use client";

import { Share2 } from "lucide-react";
import { useState } from "react";
import styles from "./card-preview.module.css";

export function CardShareButton({ id, title }: { id: string; title: string }) {
  const [status, setStatus] = useState("");
  const share = async () => {
    const url = new URL(`/watch/${encodeURIComponent(id)}`, window.location.origin).href;
    try {
      if (navigator.share) { await navigator.share({ title, url }); setStatus("Shared"); }
      else { await navigator.clipboard.writeText(url); setStatus("Link copied"); }
    } catch (error) {
      if (error instanceof DOMException && error.name === "AbortError") return;
      try { await navigator.clipboard.writeText(url); setStatus("Link copied"); }
      catch { setStatus("Couldn’t share this link."); }
    }
  };
  return <div className={styles.share}><button aria-label={`Share ${title}`} onClick={share}><Share2 size={18} /></button>{status && <span role="status">{status}</span>}</div>;
}
