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
const wait = () => new Promise((resolve) => setImmediate(resolve));

const { createOptimisticLike } = load("application/player/optimistic-like.ts");

test("like updates immediately before the request finishes", async () => {
  let done;
  let state;
  const controller = createOptimisticLike({ liked: false, likes: 5 }, () => new Promise((resolve) => { done = resolve; }), (value) => { state = value; });
  controller.toggle();
  assert.equal(state.liked, true);
  assert.equal(state.likes, 6);
  done(); await wait();
});

test("rapid like toggles serialize requests and save the final intent", async () => {
  const requests = [];
  const resolvers = [];
  let state;
  const controller = createOptimisticLike({ liked: false, likes: 5 }, (value) => { requests.push(value); return new Promise((resolve) => resolvers.push(resolve)); }, (value) => { state = value; });
  controller.toggle(); controller.toggle();
  assert.equal(state.likes, 5);
  assert.deepEqual(requests, [true]);
  resolvers.shift()(); await wait();
  assert.deepEqual(requests, [true, false]);
  resolvers.shift()(); await wait();
  assert.equal(state.liked, false);
});

test("failed like requests roll back to the confirmed count and show an error", async () => {
  let state;
  const controller = createOptimisticLike({ liked: true, likes: 5 }, async () => { throw new Error("Failed"); }, (value) => { state = value; });
  controller.toggle(); await wait();
  assert.equal(state.likes, 5);
  assert.equal(state.liked, true);
  assert.equal(state.error, "Failed");
});

test("disposed like controllers stop notifying UI and reject new toggles", async () => {
  let reject;
  let notifications = 0;
  const controller = createOptimisticLike({ liked: false, likes: 0 }, () => new Promise((resolve, fail) => { reject = fail; }), () => notifications++);
  controller.toggle(); controller.dispose(); controller.toggle();
  reject(new Error("Failed")); await wait();
  assert.equal(notifications, 1);
});

test("watch requests use real playlist URLs and authenticated uncached fetching", async () => {
  const requests = [];
  const { loadEpisode } = load("infrastructure/player/watch-repository.ts", { fetch: async (url, options) => { requests.push(options); return json(url.endsWith("playlist") ? [episode] : series); } }, cookies);
  const result = await loadEpisode(seriesId, episodeId);
  assert.equal(result.current.video_url, episode.video_url);
  assert.equal(result.current.liked, true);
  assert.equal(result.current.comments, 2);
  assert.ok(requests.every((options) => options.cache === "no-store" && options.redirect === "error" && options.headers.Authorization === "Bearer private-token"));
});

test("locked episodes never fetch or expose playlist URLs", async () => {
  let requests = 0;
  const { loadEpisode } = load("infrastructure/player/watch-repository.ts", { fetch: async () => { requests++; return json({ ...series, episodes: [{ ...series.episodes[0], locked: true }] }); } }, cookies);
  const result = await loadEpisode(seriesId, episodeId);
  assert.equal(result.locked, true);
  assert.equal(result.current, undefined);
  assert.equal(requests, 1);
});

test("missing episode IDs never silently play a different episode", async () => {
  const { loadEpisode } = load("infrastructure/player/watch-repository.ts", { fetch: async (url) => json(url.endsWith("playlist") ? [episode] : series) }, cookies);
  assert.equal(await loadEpisode(seriesId, commentId), null);
});

test("invalid IDs and comments fail before any authenticated network request", async () => {
  let requests = 0;
  const source = load("features/player/actions/comments.ts", { fetch: async () => { requests++; return json(comment); } }, cookies);
  assert.ok((await source.postComment(episodeId, " ", commentId)).error);
  assert.ok((await source.postComment(episodeId, "x".repeat(501), commentId)).error);
  assert.ok((await source.postComment("../auth", "Hello", commentId)).error);
  assert.ok((await source.updateComment("../auth", "delete")).error);
  assert.equal(requests, 0);
});

test("posted comments use the mobile endpoint and preserve idempotency keys", async () => {
  let request;
  const { postComment } = load("features/player/actions/comments.ts", { fetch: async (url, options) => { request = { url, options }; return json(comment, 201); } }, cookies);
  const result = await postComment(episodeId, " Hello ", commentId);
  assert.equal(result.data.body, "Hello");
  assert.ok(request.url.includes(`/comments/episodes/${episodeId}`));
  assert.deepEqual(JSON.parse(request.options.body), { body: "Hello", idempotency_key: commentId, parent_id: null });
});

test("comment pagination passes bounded encoded cursors and rejects malformed responses", async () => {
  let url;
  const { listComments } = load("features/player/actions/comments.ts", { fetch: async (value) => { url = value; return json({ items: [comment], next_cursor: "next" }); } }, cookies);
  assert.equal((await listComments(episodeId, "top", "a+b")).data.items.length, 1);
  assert.ok(url.includes("cursor=a%2Bb"));
  assert.ok((await listComments(episodeId, "top", "x".repeat(301))).error);
});

test("media payloads reject script URLs and comments retain plain text safely", () => {
  const { parsePlaylist, parseComment } = load("infrastructure/player/validate-player.ts");
  assert.equal(parsePlaylist([{ ...episode, video_url: "javascript:alert(1)" }], seriesId)[0].video_url, "");
  assert.equal(parseComment({ ...comment, body: "<script>alert(1)</script>" }).body, "<script>alert(1)</script>");
});

test("malformed lock metadata cannot expose an episode", async () => {
  const { parseDetails } = load("infrastructure/player/validate-player.ts");
  const episodeWithoutLock = { episode_id: episodeId, episode_number: 1, duration_seconds: 60 };
  assert.equal(parseDetails({ ...series, episodes: [episodeWithoutLock] }).episodes.length, 0);
});

test("signed-out mutations cannot reach the backend", async () => {
  let requests = 0;
  const signedOut = { "next/headers": { cookies: async () => ({ get: () => undefined }) } };
  const { setEpisodeLike } = load("features/player/actions/engagement.ts", { fetch: async () => { requests++; } }, signedOut);
  const result = await setEpisodeLike(episodeId, true);
  assert.equal(result.signIn, true);
  assert.equal(requests, 0);
});

test("series ratings preserve valid backend scores and reject invalid values", () => {
  const { parseDetails } = load("infrastructure/player/validate-player.ts");
  const rated = parseDetails({ ...series, rating_average: 8.6, rating_count: 12 });
  assert.equal(rated.rating_average, 8.6);
  assert.equal(rated.rating_count, 12);
  for (const average of [NaN, Infinity, -1, 11, "8.6"]) {
    const invalid = parseDetails({ ...series, rating_average: average, rating_count: -3 });
    assert.equal(invalid.rating_average, null);
    assert.equal(invalid.rating_count, 0);
  }
});

