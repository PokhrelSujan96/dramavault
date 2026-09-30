"use client";

import { useEffect, useRef } from "react";
import { X } from "lucide-react";
import { CommentsPanel } from "./comments-panel";
import styles from "./comments-dialog.module.css";

type Props = { episodeId: string; open: boolean; onClose: () => void; onCount: (delta: number) => void };

export function CommentsDialog({ episodeId, open, onClose, onCount }: Props) {
  const dialog = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    const element = dialog.current;
    if (!element) return;
    if (open && !element.open) element.showModal();
    if (!open && element.open) element.close();
  }, [open]);
  useEffect(() => {
    if (!open) return;
    const previous = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => { document.body.style.overflow = previous; };
  }, [open]);
  return <dialog ref={dialog} className={styles.dialog} aria-label="Episode comments" onCancel={onClose} onClose={onClose} onClick={(event) => {
    if (event.target !== event.currentTarget) return;
    const bounds = event.currentTarget.getBoundingClientRect();
    if (event.clientX < bounds.left || event.clientX > bounds.right || event.clientY < bounds.top || event.clientY > bounds.bottom) onClose();
  }}><button className={styles.close} onClick={onClose} aria-label="Close comments" autoFocus><X size={18} /></button><CommentsPanel episodeId={episodeId} enabled={open} onCount={onCount} /></dialog>;
}
