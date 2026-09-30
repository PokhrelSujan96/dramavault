import assert from "node:assert/strict";
import { test } from "node:test";
import { load } from "./runtime-loader.mjs";

const id = "12345678-1234-1234-1234-123456789abc";
const card = { series_id: id, title: "Our story", description: "Real story", genre: "Drama", thumbnail_url: "https://media.example.com/cover.jpg", episode_count: 12, free_episode_count: 3 };
const feed = { featured: [card], trending: [card], genres: [{ genre: "Drama", items: [card] }] };
const json = (value, status = 200) => new Response(JSON.stringify(value), { status });
const cookies = (token) => ({ "next/headers": { cookies: async () => ({ get: () => token ? { value: token } : undefined }) } });

const { parseHomeFeed, safeArtwork, parseSeries } = load("infrastructure/home/validate-feed.ts");
const { createHomeCatalog } = load("application/home/catalog.ts");

test("real metadata survives mapping and featured, trending, and genres deduplicate", () => {
  const catalog = createHomeCatalog(parseHomeFeed(feed), [id]);
  assert.equal(catalog.all.length, 1);
  assert.equal(catalog.featured[0].saved, true);
  assert.equal(catalog.featured[0].episodeCount, 12);
  assert.equal(catalog.featured[0].freeEpisodeCount, 3);
  assert.equal(catalog.featured[0].title, "Our story");
  assert.equal("rating" in catalog.featured[0], false);
  assert.equal("year" in catalog.featured[0], false);
});

test("malformed entries, duplicate IDs and oversized fields are constrained", () => {
  const parsed = parseSeries([card, card, { ...card, series_id: `${id}/bad` }, { ...card, series_id: "not-an-id" }, null]);
  assert.equal(parsed.length, 1);
  const invalidCount = parseSeries([{ ...card, title: "a".repeat(500), episode_count: -1 }])[0];
  assert.equal(invalidCount.title.length, 240);
  assert.equal(invalidCount.episode_count, 0);
  assert.throws(() => parseHomeFeed({}), /Invalid/);
  assert.equal(parseSeries(Array(1000).fill(card)).length, 1);
});

test("artwork rejects executable URLs, credentials, controls and unsafe local routes", () => {
  for (const source of ["javascript:alert(1)", "data:image/svg+xml,x", "//example.com/a.jpg", "https://user:password@example.com/a.jpg", "http://example.com/a.jpg", "/api/auth/google", "/_next/image?url=http://localhost", "/home/%2e%2e/file", "https://example.com/a\u0000.jpg", "https://example.com/a\\file.jpg"]) {
    assert.equal(safeArtwork(source), "", source);
  }
  assert.equal(safeArtwork(card.thumbnail_url), card.thumbnail_url);
  assert.equal(safeArtwork("/images/cover.jpg"), "/images/cover.jpg");
});

test("public home fetch never sends a token and uses bounded cache and timeout", async () => {
  let request;
  const { homeRepository } = load("infrastructure/home/home-repository.ts", { fetch: async (url, options) => { request = { url, options }; return json(feed); } });
  const result = await homeRepository.feed();
  assert.equal(result.unavailable, false);
  assert.equal(result.feed.featured[0].series_id, id);
  assert.equal(request.options.headers, undefined);
  assert.equal(request.options.next.revalidate, 60);
  assert.equal(request.options.redirect, "error");
  assert.ok(request.options.signal instanceof AbortSignal);
});

test("upstream errors, malformed JSON and network timeouts become explicit unavailable states", async () => {
  for (const fetch of [async () => json({}, 503), async () => new Response("invalid"), async () => { throw new Error("timeout"); }]) {
    const { homeRepository } = load("infrastructure/home/home-repository.ts", { fetch });
    const result = await homeRepository.feed();
    assert.equal(result.unavailable, true);
    assert.deepEqual(result.feed.featured, []);
  }
});

test("response size limit cancels the reader and rejects oversized content", async () => {
  const { readJson } = load("infrastructure/api/read-json.ts");
  let canceled = false;
  const stream = new ReadableStream({ start(controller) { controller.enqueue(new TextEncoder().encode("123456")); }, cancel() { canceled = true; } });
  await assert.rejects(() => readJson(new Response(stream), 3), /size limit/);
  assert.equal(canceled, true);
  assert.deepEqual(await readJson(json(feed)), feed);
});

test("signed-out watchlist does not call upstream", async () => {
  let called = false;
  const { libraryRepository } = load("infrastructure/home/library-repository.ts", { fetch: async () => { called = true; } }, cookies());
  const result = await libraryRepository.setSaved(id, true);
  assert.equal(result.signIn, true);
  assert.equal(called, false);
});

test("watchlist mutations keep bearer tokens server-side and never cache", async () => {
  const requests = [];
  const { libraryRepository } = load("infrastructure/home/library-repository.ts", { fetch: async (url, options) => { requests.push({ url, options }); return new Response(null, { status: 204 }); } }, cookies("test-token"));
  assert.equal((await libraryRepository.setSaved(id, true)).error, null);
  assert.equal((await libraryRepository.setSaved(id, false)).error, null);
  assert.equal(requests[0].options.method, "PUT");
  assert.equal(requests[1].options.method, "DELETE");
  assert.equal(requests[0].options.headers.Authorization, "Bearer test-token");
  assert.equal(requests[0].options.cache, "no-store");
  assert.equal(requests[0].options.redirect, "error");
});

test("invalid mutation arguments cannot reach the repository", async () => {
  const { updateWatchlist } = load("application/home/watchlist.ts");
  let calls = 0;
  const repository = { setSaved: async () => { calls++; return { error: null, signIn: false }; } };
  for (const [badId, saved] of [["../auth", true], [id, "true"], [null, true]]) {
    assert.ok((await updateWatchlist(repository, badId, saved)).error);
  }
  assert.equal(calls, 0);
  assert.equal((await updateWatchlist(repository, id, true)).error, null);
  assert.equal(calls, 1);
});

test("expired sessions redirect to sign-in; failed mutations never report success", async () => {
  for (const status of [401, 403, 404, 409, 500]) {
    const { libraryRepository } = load("infrastructure/home/library-repository.ts", { fetch: async () => json({ detail: "private backend detail" }, status) }, cookies("token"));
    const result = await libraryRepository.setSaved(id, true);
    assert.ok(result.error);
    assert.equal(result.signIn, status === 401);
    assert.equal(result.error.includes("private backend detail"), false);
  }
});
