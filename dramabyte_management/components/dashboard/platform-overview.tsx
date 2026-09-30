import { useState } from "react";
import { Clapperboard, Eye, Heart, MessageCircle, Star, Library } from "lucide-react";
import { useCachedQuery } from "@/hooks/use-cached-query";
import { useManagement } from "@/hooks/use-management";
import type { Series } from "@/components/management/management-types";
import { SeriesEpisodes } from "@/components/management/series-episodes";
import { SeriesCard, compact } from "./series-card";

type Overview = { summary: { series_count: number; episode_count: number; published_episodes: number; views: number; likes: number; comments: number; rating: number | null; rating_count: number }; daily: { day: string; views: number }[] };
export function PlatformOverview({ query, onCreate }: { query: string; onCreate: () => void }) {
  const data = useCachedQuery<Overview>("/admin/overview");
  const catalog = useManagement<Series>("/admin/series");
  const [selected, setSelected] = useState<Series>();
  const [filter, setFilter] = useState("All series");
  const summary = data.data?.summary;
  const stats = [
    [Library, "Series", summary?.series_count], [Clapperboard, "Published episodes", summary?.published_episodes],
    [Eye, "Views", summary?.views], [Heart, "Likes", summary?.likes],
    [MessageCircle, "Comments", summary?.comments], [Star, "Average rating", summary?.rating],
  ] as const;
  const days = Array.from({ length: 7 }, (_, index) => { const day = new Date(); day.setUTCDate(day.getUTCDate() - 6 + index); const date = day.toISOString().slice(0, 10); return { date, label: day.toLocaleDateString("en", { weekday: "short", timeZone: "UTC" }), views: data.data?.daily.find((item) => item.day === date)?.views ?? 0 }; });
  const max = Math.max(1, ...days.map((day) => day.views));
  const series = catalog.items.filter((item) => item.title.toLowerCase().includes(query.toLowerCase()) && (filter === "All series" || (filter === "Live" ? (item.published_episodes ?? 0) > 0 : (item.published_episodes ?? 0) === 0)));
  return <section className="platform-overview">
    <header className="platform-heading"><div><span className="platform-eyebrow">DRAMABYTE · SERIES PLATFORM</span><h1>Your stories. One minute at a time.</h1><p>Build 15-minute drama series, release episodes, and follow your audience.</p></div><button onClick={onCreate} type="button">＋ Create series</button></header>
    {(data.error || catalog.error) && <p role="alert" className="dashboard-error">{data.error || catalog.error}</p>}
    <div className="platform-stats">{stats.map(([Icon, label, value]) => <article key={label}><Icon size={19} /><span>{label}</span><strong>{value == null ? "—" : label === "Average rating" ? `${Number(value).toFixed(1)} / 5` : compact(value)}</strong><small>{label === "Average rating" ? `${summary?.rating_count ?? 0} audience ratings` : "Across your catalog"}</small></article>)}</div>
    <div className="platform-insights"><article className="analytics-card"><div className="analytics-heading"><h2>Audience activity</h2><span>Last 7 days · UTC</span></div><p>Recorded episode views</p>{data.data ? <svg viewBox="0 0 760 164" role="img" aria-label="Episode views over the last seven days">{[30, 63, 96, 130].map((y) => <line key={y} x1="20" x2="740" y1={y} y2={y} stroke="#e8ebea" strokeDasharray="3 5" />)}<polyline points={days.map((day, index) => `${20 + index * 120},${130 - day.views / max * 100}`).join(" ")} fill="none" stroke="#275b49" strokeWidth="2" />{days.map((day, index) => <g key={day.date}><circle cx={20 + index * 120} cy={130 - day.views / max * 100} r="3" fill="white" stroke="#275b49" /><text x={20 + index * 120} y="158" textAnchor="middle" fill="#87938e" fontSize="10">{day.label}</text></g>)}</svg> : <p>Audience analytics will appear when the database is connected.</p>}</article>
      <article className="series-format-card"><span>YOUR CURRENT FORMAT</span><h2>15 episodes.<br />One complete story.</h2><p>About 60 seconds per episode.<br />A hook, a turning point, and a reason to watch the next.</p><button onClick={onCreate} type="button">Plan your next series →</button></article></div>
    <div className="series-catalog-heading"><h2>Your drama series</h2><div>{["All series", "Live", "In development"].map((item) => <button key={item} aria-pressed={filter === item} onClick={() => setFilter(item)}>{item}</button>)}</div></div>
    <div className="drama-series-grid">{series.map((item) => <SeriesCard key={item.id} series={item} onOpen={() => setSelected(item)} />)}</div>
    {!series.length && <div className="series-empty"><Library size={32} /><h3>{catalog.busy ? "Opening your catalog…" : "Your next drama starts here"}</h3><p>Create a series, add its cover, and build your episode lineup.</p><button onClick={onCreate}>Create series</button></div>}
    {selected && <SeriesEpisodes series={selected} onClose={() => setSelected(undefined)} onChanged={catalog.reload} />}
  </section>;
}
