"use client";

import { useState } from "react";
import styles from "./comments.module.css";

export function CommentComposer({ send, disabled, replying = false, compact = false }: { send: (body: string) => Promise<boolean>; disabled: boolean; replying?: boolean; compact?: boolean }) {
  const [body, setBody] = useState("");
  const [sending, setSending] = useState(false);
  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (sending || disabled || !body.trim()) return;
    const draft = body; setBody(""); setSending(true);
    try { if (!await send(draft)) setBody(draft); }
    finally { setSending(false); }
  };
  return <form className={`${styles.composer} ${compact ? styles.compactComposer : ""}`} onSubmit={submit}><label className={styles.label}>{replying ? "Your reply" : "Your comment"}<textarea value={body} onChange={(event) => setBody(event.target.value)} maxLength={500} rows={compact ? 1 : 2} placeholder={replying ? "Write a reply…" : "Add a comment…"} disabled={disabled || sending} /></label><div><span>{body.length}/500</span><button type="submit" disabled={disabled || sending || !body.trim()}>{sending ? "Sending…" : "Send"}</button></div></form>;
}
