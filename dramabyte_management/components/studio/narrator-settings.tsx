import { useCachedQuery } from "@/hooks/use-cached-query";

type Preset = { narrator_reference: string; characters: { name: string; description: string }[] };

export function NarratorSettings({ school }: { school: boolean }) {
  const preset = useCachedQuery<Preset>("/generation/templates/last-seat");
  return <section className="cost-note">
    <strong>Cinematic storytelling · one narrator</strong>
    <p>All narration and quoted dialogue use the same storyteller. No lip-sync, character voices, music or extra voice-over track. Background students are visual extras only.</p>
    <p>Narrator reference: {preset.data?.narrator_reference ?? "Loading configuration…"}</p>
    <p>480p motion inputs → local 1080p finish. Actual episode length follows the complete spoken script; the target duration only guides AI script writing.</p>
    {school && <>
      <strong>Required series references</strong>
      <p>Add these four approved portraits in Series management before starting production. Keep their uniforms unchanged throughout the series.</p>
      {preset.data?.characters.map((person) => <details key={person.name}><summary>{person.name}</summary><p>{person.description}</p></details>)}
    </>}
    {preset.error && <p role="alert">{preset.error}</p>}
  </section>;
}
