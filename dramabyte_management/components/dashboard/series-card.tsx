import { Eye, Heart, MessageCircle, Star } from "lucide-react";
import type { Series } from "@/components/management/management-types";

export function SeriesCard({ series, onOpen }: { series: Series; onOpen: () => void }) {
  const count = series.episode_count ?? 0;
  const planned = series.target_episode_count ?? 15;
  return <button className="drama-series-card" onClick={onOpen} type="button">
    <div className="series-cover" style={series.thumbnail_url ? { backgroundImage: `linear-gradient(0deg,#071712dd,transparent 70%),url(${JSON.stringify(series.thumbnail_url)})` } : undefined}>
      <span className="series-genre">{series.genre || "Drama"}</span><div><span>{series.published_episodes ?? 0} episodes live</span><h3>{series.title}</h3></div>
    </div>
    <div className="series-card-body"><p>{series.description || "Add a description to introduce this series."}</p><div className="series-card-plan"><span>{count}/{planned} episodes</span><span>{Math.round((series.duration_seconds ?? 0) / 60)} min</span></div><progress value={count} max={Math.max(planned, count, 1)} />
      <div className="series-engagement"><span title="Views"><Eye size={14} />{compact(series.views ?? 0)}</span><span title="Likes"><Heart size={14} />{compact(series.likes ?? 0)}</span><span title="Comments"><MessageCircle size={14} />{compact(series.comments ?? 0)}</span><span title={`${series.rating_count ?? 0} ratings`}><Star size={14} />{series.rating == null ? "—" : Number(series.rating).toFixed(1)}</span></div>
    </div>
  </button>;
}
export function compact(value: number) { return new Intl.NumberFormat("en", { notation: "compact", maximumFractionDigits: 1 }).format(value); }
