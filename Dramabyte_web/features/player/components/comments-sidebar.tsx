"use client";

import { CommentsPanel } from "./comments-panel";
import styles from "./comments-sidebar.module.css";

type Props = { count: number; id: string; episodeId: string; onCount: (delta: number) => void };

export function CommentsSidebar({ count, id, episodeId, onCount }: Props) {
  return <aside id={id} className={styles.sidebar} aria-label="Episode comments"><CommentsPanel count={count} episodeId={episodeId} enabled onCount={onCount} /></aside>;
}
