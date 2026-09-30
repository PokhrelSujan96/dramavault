import assert from "node:assert/strict";
import { test } from "node:test";
import { load } from "./runtime-loader.mjs";

const seriesId = "12345678-1234-1234-1234-123456789abc";
const episodeId = "22345678-1234-1234-1234-123456789abc";
const commentId = "32345678-1234-1234-1234-123456789abc";
const series = { series_id: seriesId, title: "Real series", description: "Story", genre: "Drama", thumbnail_url: "", episode_count: 1, episodes: [{ episode_id: episodeId, episode_number: 1, title: "Episode one", duration_seconds: 60, locked: false }] };
const episode = { ...series, episode_id: episodeId, episode_number: 1, duration_seconds: 60, video_url: "https://media.example.com/published/video.mp4?revision=123", likes: 4, liked: true, comments: 2 };
const comment = { id: commentId, episode_id: episodeId, parent_id: null, body: "Hello", author_name: "Viewer", created_at: new Date().toISOString(), is_mine: true, like_count: 2, reply_count: 0, liked: false };
const cookies = { "next/headers": { cookies: async () => ({ get: () => ({ value: "private-token" }) }) } };
const json = (value, status = 200) => new Response(JSON.stringify(value), { status });

test("guests use public preview routes without credentials", async () => {
  const requests = [];
  const guest = { "next/headers": { cookies: async () => ({ get: () => undefined }) } };
  const { loadEpisode } = load("infrastructure/player/watch-repository.ts", { fetch: async (url, options) => {
    requests.push([url, options]);
    return json(url.endsWith("/playlist") ? [episode] : series);
  } }, guest);
  const result = await loadEpisode(seriesId, episodeId);
  assert.equal(result.current.episode_id, episodeId);
  assert.equal(requests.length, 2);
  assert.ok(requests.every(([url, options]) => url.includes("/public/series/") && !options.headers && options.cache === "no-store"));
});

test("guests cannot bypass the first-two limit with an unlocked backend flag", async () => {
  let calls = 0;
  const guest = { "next/headers": { cookies: async () => ({ get: () => undefined }) } };
  const { loadEpisode } = load("infrastructure/player/watch-repository.ts", { fetch: async () => {
    calls++;
    return json({ ...series, episodes: [{ ...series.episodes[0], episode_number: 3, locked: false }] });
  } }, guest);
  const result = await loadEpisode(seriesId, episodeId);
  assert.equal(result.locked, true);
  assert.equal(result.current, undefined);
  assert.equal(calls, 1);
});

test("comment access checks block guests before any private fetch", async () => {
  let calls = 0;
  const guest = { "next/headers": { cookies: async () => ({ get: () => undefined }) } };
  const { checkCommentAccess } = load("features/player/actions/comment-access.ts", { fetch: async () => { calls++; return json({}); } }, guest);
  const result = await checkCommentAccess();
  assert.equal(result.signIn, true);
  assert.match(result.error, /sign in/);
  assert.equal(calls, 0);
});

test("comment access checks verify sessions with the backend", async () => {
  for (const status of [200, 401, 503]) {
    const { checkCommentAccess } = load("features/player/actions/comment-access.ts", { fetch: async () => json({}, status) }, cookies);
    const result = await checkCommentAccess();
    assert.equal(result.error === undefined, status === 200);
    assert.equal(result.signIn === true, status === 401);
  }
});

test("guests can read public comments but cannot post", async () => {
  const requests = [];
  const guest = { "next/headers": { cookies: async () => ({ get: () => undefined }) } };
  const source = load("features/player/actions/comments.ts", { fetch: async (url, options) => {
    requests.push([url, options]);
    return json({ items: [{ ...comment, is_mine: false, liked: false }], next_cursor: null });
  } }, guest);
  const page = await source.listComments(episodeId, "top");
  assert.equal(page.data.items.length, 1);
  assert.equal(page.data.can_post, false);
  assert.match(requests[0][0], /\/public\/comments\/episodes\//);
  assert.equal(requests[0][1].headers, undefined);
  const posted = await source.postComment(episodeId, "Hello", commentId);
  assert.equal(posted.signIn, true);
  assert.equal(requests.length, 1);
});

test("expired sessions can read comments as guests without gaining posting access", async () => {
  const { listComments } = load("features/player/actions/comments.ts", { fetch: async (url) => url.includes("/public/") ? json({ items: [comment], next_cursor: null }) : json({}, 401) }, cookies);
  const result = await listComments(episodeId, "new");
  assert.equal(result.data.items.length, 1);
  assert.equal(result.data.can_post, false);
});

