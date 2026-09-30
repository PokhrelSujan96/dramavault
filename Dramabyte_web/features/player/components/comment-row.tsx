"use client";

import { Heart } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import type { EpisodeComment } from "@/domain/player/contracts";
import { createOptimisticLike } from "@/application/player/optimistic-like";
import { updateComment } from "../actions/comments";
import { CommentReplies } from "./comment-replies";
import styles from "./comments.module.css";

export function CommentRow({ item, remove, onCount, reply = false, canPost = true }: { item: EpisodeComment; remove: (item: EpisodeComment) => Promise<void>; onCount: (delta: number) => void; reply?: boolean; canPost?: boolean }) {
  const [liked, setLiked] = useState(item.liked);
  const [likes, setLikes] = useState(item.like_count);
  const [replyCount, setReplyCount] = useState(item.reply_count);
  const [openedReplies, setOpenedReplies] = useState(false);
  const [expanded, setExpanded] = useState(false);
  const [reporting, setReporting] = useState(false);
  const [reason, setReason] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [reported, setReported] = useState(false);
  const busy = useRef(false);
  const mounted = useRef(false);
  useEffect(() => { mounted.current = true; return () => { mounted.current = false; }; }, []);
  const [like] = useState(() => createOptimisticLike({ liked: item.liked, likes: item.like_count }, async (value) => {
    const result = await updateComment(item.id, "like", value);
    if (result.error) throw new Error(result.error);
  }, (state) => { setLiked(state.liked); setLikes(state.likes); setError(state.error); }));
  useEffect(() => { like.activate(); return () => like.dispose(); }, [like]);
  const report = async (event: React.FormEvent) => {
    event.preventDefault();
    if (busy.current || !reason.trim()) return;
    busy.current = true; setError(null); setReported(true); setReporting(false);
    try {
      const result = await updateComment(item.id, "report", reason);
      if (result.error) throw new Error(result.error);

    } catch (failure) { if (mounted.current) { setReported(false); setReporting(true); setError(failure instanceof Error ? failure.message : "Couldn’t report this comment."); } }
    finally { busy.current = false; }
  };
  return <article className={styles.comment}><span className={styles.commentAvatar} aria-hidden="true">{item.author_name.slice(0, 1).toUpperCase()}</span><header><strong>{item.author_name}</strong>{item.pending && <span>Sending…</span>}</header><p>{item.body}</p><div className={styles.actions}><button aria-pressed={liked} disabled={item.pending || !canPost} onClick={like.toggle}><Heart size={13} fill={liked ? "currentColor" : "none"} />{likes}</button>{!reply && <button disabled={item.pending} onClick={() => { setExpanded(!expanded); setOpenedReplies(true); }} aria-expanded={expanded}>Reply{replyCount ? ` · ${replyCount}` : ""}</button>}{!canPost ? null : item.is_mine ? <button disabled={item.pending} onClick={() => void remove(item)}>Delete</button> : <button disabled={item.pending || reported} onClick={() => setReporting(!reporting)}>{reported ? "Reported" : "Report"}</button>}</div>{error && <p className={styles.error} role="status">{error}</p>}{reporting && <form className={styles.report} onSubmit={report}><input aria-label="Reason for reporting" value={reason} maxLength={200} onChange={(event) => setReason(event.target.value)} placeholder="Why are you reporting this?" required /><button type="submit">Report</button></form>}{!reply && <div hidden={!expanded}>{openedReplies && <CommentReplies episodeId={item.episode_id} parentId={item.id} onCount={(delta) => { setReplyCount((value) => Math.max(0, value + delta)); onCount(delta); }} />}</div>}</article>;
}
