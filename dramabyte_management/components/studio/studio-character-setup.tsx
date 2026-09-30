import { CharacterLibrary } from "@/components/management/character-library";
import { useCachedQuery } from "@/hooks/use-cached-query";
import type { HybridState } from "./hybrid-types";

export function StudioCharacterSetup({ projectId, school }: { projectId: string; school: boolean }) {
  const context = useCachedQuery<HybridState>(`/generation/project/${projectId}/hybrid`);
  const preset = useCachedQuery<{ characters: { name: string; description: string }[] }>("/generation/templates/last-seat");
  if (!context.data?.series_id) return null;
  return <section className="hybrid-production">
    <h2>Step 1 · Set up consistent characters</h2>
    <p>Add approved reference portraits before starting paid production. This upload step does not generate media or spend provider credits.</p>
    {school && preset.data?.characters.map((person) => <details key={person.name}>
      <summary>{person.name} · required portrait</summary><p>{person.description}</p>
    </details>)}
    <CharacterLibrary seriesId={context.data.series_id} presets={school ? preset.data?.characters : undefined} onChanged={context.reload} />
  </section>;
}
