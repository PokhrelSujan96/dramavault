"use client";

import { useComments } from "../hooks/use-comments";
import { CommentSignIn } from "./comment-signin";
import { CommentComposer } from "./comment-composer";
import { CommentRow } from "./comment-row";
import styles from "./comments.module.css";

export function CommentReplies({ episodeId, parentId, onCount }: { episodeId: string; parentId: string; onCount: (delta: number) => void }) {
  const state = useComments(episodeId, true, onCount, parentId);
  return <div className={styles.replies}>{state.canPost ? <CommentComposer send={state.send} disabled={!state.loaded || state.loading || state.posting} replying /> : state.loaded ? <CommentSignIn /> : null}{state.error && <p role="status">{state.error}<button onClick={() => void state.load()}>Retry</button></p>}{state.loading && <p role="status">Loading replies…</p>}{state.items.map((item) => <CommentRow key={item.id} item={item} canPost={state.canPost} remove={state.remove} onCount={onCount} reply />)}{state.cursor && state.items.length < 200 && <button disabled={state.loading} onClick={() => void state.load(true)}>More replies</button>}</div>;
}
