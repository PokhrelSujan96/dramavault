import { loadHome } from "@/application/home/load-home";
import { homeRepository } from "@/infrastructure/home/home-repository";
import { getSavedSeries } from "@/infrastructure/home/library-repository";
import { TitleRail } from "@/features/home/components/reference/title-rail";
import { HomeFooter } from "@/features/home/components/reference/home-footer";

export const metadata = { title: "Discover" };

export default async function DiscoverPage() {
  const { catalog, unavailable } = await loadHome(homeRepository, getSavedSeries().then((items) => items.map((item) => item.series_id)));
  return <main><header className="container page-intro"><h1>Discover</h1><p>Find your next story, or explore a favorite genre.</p></header>{catalog.all.length ? <><TitleRail title="Explore series" items={catalog.all} portrait />{!!catalog.trending.length && <TitleRail title="Trending now" items={catalog.trending} />}{catalog.genres.map((rail) => <TitleRail key={rail.genre} title={rail.genre} items={rail.items} genre />)}</> : <p className="container empty">{unavailable ? "Couldn’t load series. Please try again shortly." : "New series are coming soon."}</p>}<HomeFooter /></main>;
}
