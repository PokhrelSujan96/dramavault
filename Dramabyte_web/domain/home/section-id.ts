export function homeSectionId(title: string, genre = false): string {
  const slug = genre ? Array.from(title).map((character) => character.codePointAt(0)?.toString(16)).join("-") : title.toLowerCase().replaceAll(" ", "-");
  return `${genre ? "genre-" : ""}${slug}`;
}
