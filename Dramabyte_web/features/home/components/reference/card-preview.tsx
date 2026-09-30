"use client";

import { createPortal } from "react-dom";
import { useEffect, useId, useRef, useState, type ReactNode } from "react";
import type { HomeTitle } from "@/domain/home/title";
import { HomeArtwork } from "./home-artwork";
import { TitleActions } from "./title-actions";
import { CardShareButton } from "./card-share-button";
import styles from "./card-preview.module.css";

type Props = { item: HomeTitle; children: ReactNode };

export function CardPreview({ item, children }: Props) {
  const anchor = useRef<HTMLDivElement>(null);
  const panel = useRef<HTMLDivElement>(null);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [position, setPosition] = useState<{ left: number; top: number; width: number } | null>(null);
  const id = useId();
  const cancel = () => { if (timer.current) clearTimeout(timer.current); timer.current = null; };
  const close = () => { cancel(); setPosition(null); };
  const open = () => {
    cancel();
    const bounds = anchor.current?.getBoundingClientRect();
    if (!bounds) return;
    const width = Math.min(240, window.innerWidth - 32);
    const height = Math.min(390, window.innerHeight - 32);
    setPosition({ width, left: Math.max(16, Math.min(bounds.left - (width - bounds.width) / 2, window.innerWidth - width - 16)), top: Math.max(16, Math.min(bounds.top - 12, window.innerHeight - height - 16)) });
  };
  const leave = () => { cancel(); timer.current = setTimeout(close, 160); };
  const blur = (target: EventTarget | null) => {
    if (target instanceof Node && (anchor.current?.contains(target) || panel.current?.contains(target))) return;
    leave();
  };
  useEffect(() => () => { if (timer.current) clearTimeout(timer.current); }, []);
  useEffect(() => {
    if (!position) return;
    const dismiss = (event: Event) => {
      if (event.type === "keydown" && (event as KeyboardEvent).key !== "Escape") return;
      if (event.type === "scroll" && event.target instanceof Node && panel.current?.contains(event.target)) return;
      if (event.type === "pointerdown" && event.target instanceof Node && (anchor.current?.contains(event.target) || panel.current?.contains(event.target))) return;
      if (event.type === "keydown") anchor.current?.querySelector<HTMLAnchorElement>("a")?.focus();
      setPosition(null);
    };
    window.addEventListener("scroll", dismiss, true);
    window.addEventListener("resize", dismiss);
    document.addEventListener("keydown", dismiss);
    document.addEventListener("pointerdown", dismiss);
    return () => {
      window.removeEventListener("scroll", dismiss, true);
      window.removeEventListener("resize", dismiss);
      document.removeEventListener("keydown", dismiss);
      document.removeEventListener("pointerdown", dismiss);
    };
  }, [position]);
  return <div ref={anchor} className={styles.anchor} onPointerEnter={(event) => { if (event.pointerType === "mouse") open(); }} onPointerLeave={leave} onFocus={open} onBlur={(event) => blur(event.relatedTarget)}>{children}{position && createPortal(<div ref={panel} id={id} className={styles.preview} style={position} role="region" aria-label={`${item.title} preview`} onPointerEnter={cancel} onPointerLeave={leave} onFocus={cancel} onBlur={(event) => blur(event.relatedTarget)}><div className={styles.art}><HomeArtwork src={item.image} title={item.title} fill sizes="240px" /></div><div className={styles.body}><h3>{item.title}</h3><p className={styles.meta}>{item.genre} · {item.episodeCount} {item.episodeCount === 1 ? "episode" : "episodes"}</p>{item.description && <p className={styles.description}>{item.description}</p>}<div className={styles.actions}><TitleActions item={item} compact /><CardShareButton id={item.id} title={item.title} /></div></div></div>, document.body)}</div>;
}
