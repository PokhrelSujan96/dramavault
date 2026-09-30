import { SeriesCard } from "@/features/catalog/components/series-card";
import { searchSeries } from "@/infrastructure/api/server";
import styles from "./page.module.css";
export const metadata={title:"Search"};
export default async function SearchPage({searchParams}:{searchParams:Promise<{q?:string}>}){const {q=""}=await searchParams;const items=await searchSeries(q);return <><main className={`container page-shell ${styles.page}`}><h1>Search Dramabyte</h1><form><input className="input" name="q" defaultValue={q} autoFocus placeholder="Search dramas or series"/><button className="button button-red">Search</button></form>{q&&<p className="muted">{items.length} results for “{q}”</p>}<div className="card-grid">{items.map((item,index)=><SeriesCard key={item.series_id} item={item} index={index}/>)}</div></main></>}
