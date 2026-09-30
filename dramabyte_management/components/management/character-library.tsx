import { useState } from "react";
import { apiRequest } from "@/lib/api-client";
import { useManagement } from "@/hooks/use-management";

type Character = { id: string; name: string; description: string; reference_url: string };

type ReferencePreset = { name: string; description: string };
type Props = { seriesId: string; presets?: ReferencePreset[]; onChanged?: () => Promise<void> };

export function CharacterLibrary({ seriesId, presets, onChanged }: Props) {
  const characters = useManagement<Character>(`/admin/series/${seriesId}/characters`);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [file, setFile] = useState<File>();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function add() {
    if (!file) return;
    setBusy(true); setError("");
    const body = new FormData();
    body.set("name", name); body.set("description", description); body.set("portrait", file);
    try {
      await apiRequest(`/admin/series/${seriesId}/characters`, { method: "POST", body });
      setName(""); setDescription(""); setFile(undefined);
      await characters.reload();
      await onChanged?.();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Unable to add character");
    } finally { setBusy(false); }
  }

  return <section className="character-library">
    <h3>Series character bible</h3>
    <p>Upload one approved portrait per character. Every episode reuses these identity references. Describe age, face, hair, outfit and distinguishing features. References are immutable; add them before production.</p>
    {(error || characters.error) && <p role="alert" className="dashboard-error">{error || characters.error}</p>}
    <div className="character-grid">{characters.items.map((character) => <article key={character.id}>
      <img src={character.reference_url} alt={character.name} />
      <strong>{character.name}</strong><p>{character.description}</p>
    </article>)}</div>
    <form onSubmit={(event) => { event.preventDefault(); void add(); }}>
      {presets && <label>Character preset<select value={presets.some((person) => person.name === name) ? name : ""} onChange={(event) => {
        const person = presets.find((item) => item.name === event.target.value);
        if (person) { setName(person.name); setDescription(person.description); }
      }}><option value="">Select a character to fill identity and outfit</option>{presets.filter((person) => !characters.items.some((item) => item.name.toLowerCase() === person.name.toLowerCase())).map((person) => <option key={person.name} value={person.name}>{person.name}</option>)}</select></label>}
      <label>Name<input required maxLength={80} value={name} onChange={(event) => setName(event.target.value)} /></label>
      <label>Identity and wardrobe<textarea required minLength={20} maxLength={2000} value={description} onChange={(event) => setDescription(event.target.value)} /></label>
      <label>Approved portrait<input required type="file" accept="image/png,image/jpeg,image/webp" onChange={(event) => setFile(event.target.files?.[0])} /></label>
      <button disabled={busy || !file}>{busy ? "Saving portrait…" : "Add character reference"}</button>
    </form>
  </section>;
}
