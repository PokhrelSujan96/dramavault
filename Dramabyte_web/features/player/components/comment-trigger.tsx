"use client";

import { MessageCircle } from "lucide-react";
import styles from "./player.module.css";

export function CommentTrigger({ count, open, onOpen, panelId }: { count: number; open: boolean; onOpen: () => void; panelId: string }) {
  return <div className={styles.likeControl}><button type="button" onClick={onOpen} aria-expanded={open} aria-controls={panelId} data-comment-trigger><MessageCircle /><span>{count} comments</span></button></div>;
}
