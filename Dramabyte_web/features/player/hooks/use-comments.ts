"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import type { EpisodeComment } from "@/domain/player/contracts";
import { listComments, postComment, updateComment } from "../actions/comments";

export function useComments(episodeId: string, enabled: boolean, onCount: (delta: number) => void, parentId: string | null = null) {
  const [canPost, setCanPost] = useState(false);
  const [items, setItems] = useState<EpisodeComment[]>([]);
  const [loaded, setLoaded] = useState(false);
  const [loading, setLoading] = useState(false);
  const [posting, setPosting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [cursor, setCursor] = useState<string | null>(null);
  const [sort, setSort] = useState<"top" | "new">("top");
  const mounted = useRef(false);
  const inFlight = useRef(false);
  const postingNow = useRef(false);
  const requestId = useRef(0);
  const retry = useRef<{ body: string; key: string } | null>(null);
  useEffect(() => { mounted.current = true; return () => { mounted.current = false; }; }, []);
  const load = useCallback(async (more = false) => {
    if (inFlight.current || postingNow.current) return;
    inFlight.current = true;
    const generation = ++requestId.current;
    setLoading(true); setError(null);
    try {
      const result = await listComments(parentId ?? episodeId, sort, more ? cursor : null, !!parentId);
      if (!mounted.current || requestId.current !== generation) return;
      if (result.error) { setError(result.error); return; }
      const page = result.data!;
      setCanPost(page.can_post === true);
      setItems((current) => Array.from(new Map([...(more ? current : []), ...page.items].map((item) => [item.id, item])).values()).slice(0, 200));
      setCursor(page.next_cursor); setLoaded(true);
    } catch { if (mounted.current) setError("Couldn’t load comments. Please try again."); }
    finally { inFlight.current = false; if (mounted.current) setLoading(false); }
  }, [episodeId, parentId, sort, cursor]);
  useEffect(() => {
    if (!enabled || loaded) return;
    void load();
  }, [enabled, loaded, load]);
  const changeSort = (value: "top" | "new") => { if (loading || posting || sort === value) return; setLoaded(false); setSort(value); };
  const send = async (body: string) => {
    const clean = body.trim();
    if (postingNow.current || inFlight.current || !loaded || !clean || clean.length > 500) return false;
    postingNow.current = true;
    const key = retry.current?.body === clean ? retry.current.key : crypto.randomUUID();
    retry.current = { body: clean, key };
    const temporary: EpisodeComment = { id: key, episode_id: episodeId, parent_id: parentId, body: clean, author_name: "You", created_at: new Date().toISOString(), like_count: 0, reply_count: 0, liked: false, is_mine: true, pending: true };
    setPosting(true); setError(null); setItems((current) => [temporary, ...current].slice(0, 200)); onCount(1);
    try {
      const result = await postComment(episodeId, clean, key, parentId);
      if (result.error) throw new Error(result.error);
      if (mounted.current) setItems((current) => current.map((item) => item.id === key ? result.data! : item));
      retry.current = null;
      return true;
    } catch (failure) {
      onCount(-1);
      if (mounted.current) { setItems((current) => current.filter((item) => item.id !== key)); setError(failure instanceof Error ? failure.message : "Couldn’t post your comment."); }
      return false;
    } finally { postingNow.current = false; if (mounted.current) setPosting(false); }
  };
  const remove = async (item: EpisodeComment) => {
    const index = items.findIndex((entry) => entry.id === item.id);
    setItems((current) => current.filter((entry) => entry.id !== item.id)); onCount(-1); setError(null);
    try {
      const result = await updateComment(item.id, "delete");
      if (result.error) throw new Error(result.error);
    } catch (failure) {
      onCount(1);
      if (mounted.current) { setItems((current) => { const restored = [...current]; restored.splice(Math.max(0, index), 0, item); return restored.slice(0, 200); }); setError(failure instanceof Error ? failure.message : "Couldn’t delete the comment."); }
    }
  };
  return { canPost, items, loading, loaded, posting, error, cursor, sort, changeSort, load, send, remove };
}
