import assert from "node:assert/strict";
import { test } from "node:test";
import { load } from "./runtime-loader.mjs";

const episodeId = "22345678-1234-1234-1234-123456789abc";
const commentId = "32345678-1234-1234-1234-123456789abc";
const cookies = { "next/headers": { cookies: async () => ({ get: () => ({ value: "private-token" }) }) } };
const json = (value, status = 200) => new Response(JSON.stringify(value), { status });
const wait = () => new Promise((resolve) => setImmediate(resolve));

const { createViewTracker } = load("application/player/view-tracker.ts");
test("views count after two seconds of active watch time and pause resumes do not double count", async () => {
  const events = [];
  const tracker = createViewTracker(async (id) => { events.push(id); return true; }, () => "watch-one");
  for (const time of [100, 600, 1100, 1600]) tracker.tick(time, true);
  assert.equal(events.length, 0);
  tracker.tick(2100, true);
  await wait();
  tracker.tick(2200, false);
  tracker.tick(5000, true);
  tracker.tick(5500, true);
  assert.deepEqual(events, ["watch-one"]);
  tracker.reset();
  for (const time of [6000, 6500, 7000, 7500, 8000]) tracker.tick(time, true);
  await wait();
  assert.equal(events.length, 2);
});
test("failed view retries reuse the same event and inactive time does not qualify", async () => {
  const events = [];
  const tracker = createViewTracker(async (id) => { events.push(id); return false; }, () => "retry-event");
  tracker.tick(100, true); tracker.tick(500, false); tracker.tick(50000, true);
  assert.equal(events.length, 0);
  for (const time of [50500, 51000, 51500, 52000]) tracker.tick(time, true);
  await wait();
  tracker.tick(58000, true);
  await wait();
  assert.deepEqual(events, ["retry-event", "retry-event"]);
});
test("episode ratings use mobile endpoints and reject invalid scores before network requests", async () => {
  const calls = [];
  const { rateEpisode } = load("features/player/actions/rating.ts", { fetch: async (url, options) => {
    calls.push([url, options]); return json({ average: 8, count: 1, my_rating: 8 });
  } }, cookies);
  assert.ok((await rateEpisode(episodeId, 11)).error);
  assert.equal(calls.length, 0);
  assert.equal((await rateEpisode(episodeId, 8)).data.my_rating, 8);
  assert.match(calls[0][0], /\/ratings\/episodes\//);
  assert.equal(calls[0][1].method, "PUT");
});
test("guest views submit one event without credentials and guest ratings cannot submit", async () => {
  const guest = { "next/headers": { cookies: async () => ({ get: () => undefined }) } };
  const calls = [];
  const { recordPlaybackView } = load("features/player/actions/views.ts", { fetch: async (url, options) => { calls.push([url, options]); return new Response(null, { status: 204 }); } }, guest);
  assert.equal(await recordPlaybackView(episodeId, commentId), true);
  assert.match(calls[0][0], /\/public\/views$/);
  assert.equal(calls[0][1].headers.Authorization, undefined);
  const { rateEpisode } = load("features/player/actions/rating.ts", { fetch: async () => { throw new Error("Must not request"); } }, guest);
  assert.equal((await rateEpisode(episodeId, 5)).signIn, true);
});
