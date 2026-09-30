"use client";

import { useComments } from "../hooks/use-comments";
import { CommentsLoading } from "./comments-loading";
import { CommentSignIn } from "./comment-signin";
import { CommentComposer } from "./comment-composer";
import { CommentRow } from "./comment-row";
import styles from "./comments.module.css";

export function CommentsPanel({ episodeId, enabled, onCount, count }: { episodeId: string; enabled: boolean; onCount: (delta: number) => void; count?: number }) {
  const state = useComments(episodeId, enabled, onCount);
  return <section className={styles.panel} aria-label="Comments"><header><h2>Comments {count !== undefined && <span>{count.toLocaleString()}</span>}</h2><select aria-label="Sort comments" value={state.sort} disabled={state.loading || state.posting} onChange={(event) => state.changeSort(event.target.value as "top" | "new")}><option value="new">Newest</option><option value="top">Top</option></select></header><div className={styles.scrollArea}>{state.error && <p role="status" className={styles.error}>{state.error}<button onClick={() => void state.load()}>Retry</button></p>}{(state.loading || !state.loaded) && !state.error && <CommentsLoading />}{!state.items.length && state.loaded && <p className={styles.empty}>Be the first to comment.</p>}<div className={styles.list}>{state.items.map((item) => <CommentRow key={item.id} item={item} canPost={state.canPost} remove={state.remove} onCount={onCount} />)}</div>{state.cursor && state.items.length < 200 && <button className={styles.more} disabled={state.loading} onClick={() => void state.load(true)}>Load more</button>}</div>{state.canPost ? <CommentComposer compact send={state.send} disabled={!state.loaded || state.loading || state.posting} /> : state.loaded ? <CommentSignIn /> : null}</section>;
}
