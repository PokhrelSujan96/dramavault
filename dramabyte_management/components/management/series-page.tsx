import { useState } from "react";
import { useManagement } from "@/hooks/use-management";
import type { Series } from "./management-types";
import { SeriesEpisodes } from "./series-episodes";
import { SeriesFields, defaultSeriesMetadata } from "./series-fields";
import { SeriesCard } from "@/components/dashboard/series-card";

export function SeriesPage({ query }: { query: string }) {
  const data = useManagement<Series>("/admin/series");
  const [selected, setSelected] = useState<Series>();
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [metadata, setMetadata] = useState(defaultSeriesMetadata);
  return <section className="management-page"><header><div><h1>Series & episodes</h1><p>Organize your dramas into series with ordered episodes.</p></div></header>
    {data.error && <p className="dashboard-error" role="alert">{data.error}</p>}
    <form className="management-card management-form" onSubmit={(event) => { event.preventDefault(); void data.mutate("/admin/series", "POST", { title, description, ...metadata }).then((success) => { if (success) { setTitle(""); setDescription(""); setMetadata(defaultSeriesMetadata); } }); }}><h2>Create series</h2><label>Title<input required maxLength={160} value={title} onChange={(event) => setTitle(event.target.value)} /></label><label>Description<textarea maxLength={5000} value={description} onChange={(event) => setDescription(event.target.value)} /></label><SeriesFields value={metadata} onChange={setMetadata} /><button disabled={data.busy}>Create series</button></form>
    <div className="drama-series-grid">{data.items.filter((item) => item.title.toLowerCase().includes(query.toLowerCase())).map((series) => <SeriesCard key={series.id} series={series} onOpen={() => setSelected(series)} />)}</div>
    {!data.items.length && <p className="empty-state">{data.busy ? "Loading series…" : "Create your first series above."}</p>}
    {selected && <SeriesEpisodes key={selected.id} series={selected} onClose={() => setSelected(undefined)} onChanged={data.reload} />}
  </section>;
}
