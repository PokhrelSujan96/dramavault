import { loadHome } from "@/application/home/load-home";
import { homeRepository } from "@/infrastructure/home/home-repository";
import { getSavedSeries } from "@/infrastructure/home/library-repository";
import { ReferenceHome } from "@/features/home/components/reference/reference-home";

export default async function HomePage() {
  const home = await loadHome(homeRepository, getSavedSeries().then((items) => items.map((item) => item.series_id)));
  return <ReferenceHome {...home} />;
}
