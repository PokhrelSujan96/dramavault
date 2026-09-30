"use client";

import Image from "next/image";
import { Film } from "lucide-react";
import { useState } from "react";
import styles from "./cards.module.css";

export function HomeArtwork({ src, title, fill = false, width, height, sizes }: { src: string; title: string; fill?: boolean; width?: number; height?: number; sizes?: string }) {
  const [failedSource, setFailedSource] = useState<string | null>(null);
  if (!src || failedSource === src) return <span className={styles.artworkFallback} aria-label={`${title} artwork unavailable`}><Film size={30} /></span>;
  return <Image src={src} alt={`${title} artwork`} fill={fill} width={width} height={height} sizes={sizes} unoptimized={src.startsWith("https:")} referrerPolicy="no-referrer" onError={() => setFailedSource(src)} />;
}
