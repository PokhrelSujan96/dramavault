import { SeriesCard as Series } from "@/domain/models";
import { SeriesCard } from "./series-card";

export function SeriesRail({ title, items }: { title: string; items: Series[] }) {
  return <section className="section"><div className="section-head"><h2 className="section-title">{title}</h2><span className="muted">View all</span></div><div className="card-grid">{items.map((item,index)=><SeriesCard key={item.series_id} item={item} index={index}/>)}</div></section>;
}
