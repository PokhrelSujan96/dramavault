"use client";

import { Heart } from "lucide-react";
import { useEffect, useId, useState } from "react";
import type { PlaylistItem } from "@/domain/models";
import { createOptimisticLike } from "@/application/player/optimistic-like";
import { setEpisodeLike } from "../actions/engagement";
import { EpisodeRating } from "./episode-rating";
import { ActionTooltip } from "./action-tooltip";
import { ShareButton } from "./share-button";
import styles from "./player.module.css";

export function EngagementControls({ current }: { current: PlaylistItem }) {
  const tooltipId = useId();
  const [liked, setLiked] = useState(current.liked ?? false);
  const [likes, setLikes] = useState(current.likes);
  const [error, setError] = useState<string | null>(null);
  const [like] = useState(() => createOptimisticLike({ liked: current.liked ?? false, likes: current.likes }, async (value) => {
    const result = await setEpisodeLike(current.episode_id, value);
    if (result.error) throw new Error(result.error);
  }, (state) => { setLiked(state.liked); setLikes(state.likes); setError(state.error); }));
  useEffect(() => { like.activate(); return () => like.dispose(); }, [like]);
  return <><div className={styles.engagement}><div className={styles.likeControl}><button onClick={like.toggle} aria-describedby={error ? tooltipId : undefined} aria-pressed={liked} aria-label={liked ? "Unlike episode" : "Like episode"} className={liked ? styles.active : ""}><Heart fill={liked ? "currentColor" : "none"} /><span>{likes}</span></button><ActionTooltip key={error ?? "none"} message={error} id={tooltipId} /></div><EpisodeRating current={current} /><ShareButton title={current.title} seriesId={current.series_id} episodeId={current.episode_id} /></div></>;
}
