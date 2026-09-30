"use client";

import { useEffect, useState } from "react";
import styles from "./action-tooltip.module.css";

export function ActionTooltip({ message, id }: { message: string | null; id: string }) {
  const [dismissed, setDismissed] = useState<string | null>(null);
  useEffect(() => {
    if (!message) return;
    const dismiss = () => setDismissed(message);
    const escape = (event: KeyboardEvent) => { if (event.key === "Escape") dismiss(); };
    const timer = window.setTimeout(dismiss, 5000);
    document.addEventListener("pointerdown", dismiss);
    document.addEventListener("keydown", escape);
    return () => {
      window.clearTimeout(timer);
      document.removeEventListener("pointerdown", dismiss);
      document.removeEventListener("keydown", escape);
    };
  }, [message]);
  if (!message || dismissed === message) return null;
  return <span id={id} className={styles.tooltip} role="tooltip"><span role="status">{message}</span></span>;
}
