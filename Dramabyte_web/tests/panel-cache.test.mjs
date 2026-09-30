import assert from "node:assert/strict";
import { test } from "node:test";
import { load } from "./runtime-loader.mjs";

const { createPanelCache } = load("application/account/panel-cache.ts");
const first = { series_id: "one", title: "First" };
const second = { series_id: "two", title: "Second" };
const deferred = () => { let resolve; const promise = new Promise((done) => { resolve = done; }); return { promise, resolve }; };

test("reopening and concurrent requests reuse the cached panel", async () => {
  let requests = 0;
  const response = deferred();
  const cache = createPanelCache(() => { requests++; return response.promise; });
  const firstLoad = cache.load("library");
  const duplicate = cache.load("library");
  assert.equal(firstLoad, duplicate);
  response.resolve({ library: [first] });
  await firstLoad;
  await cache.load("library");
  assert.equal(requests, 1);
  assert.equal(cache.snapshot("library").library[0], first);
});

test("cached library removals happen immediately and roll back in order", async () => {
  const cache = createPanelCache(async () => ({ library: [first, second] }));
  await cache.load("library");
  const change = cache.editLibrary(first, false);
  assert.deepEqual(cache.snapshot("library").library, [second]);
  change.rollback();
  assert.deepEqual(cache.snapshot("library").library, [first, second]);
});

test("homepage saves update an already-loaded library without another fetch", async () => {
  let requests = 0;
  const cache = createPanelCache(async () => { requests++; return { library: [first] }; });
  await cache.load("library");
  cache.editLibrary(second, true).commit();
  await cache.load("library");
  assert.deepEqual(cache.snapshot("library").library, [second, first]);
  assert.equal(requests, 1);
});

test("separate sessions do not share private cached data", async () => {
  const firstSession = createPanelCache(async () => ({ library: [first] }));
  const nextSession = createPanelCache(async () => ({ library: [second] }));
  await firstSession.load("library");
  assert.equal(nextSession.snapshot("library"), null);
  firstSession.clear();
  assert.equal(firstSession.snapshot("library"), null);
});

test("cleared caches ignore outstanding responses", async () => {
  const response = deferred();
  const cache = createPanelCache(() => response.promise);
  const pending = cache.load("profile");
  cache.clear();
  response.resolve({ profile: { display_name: "Private viewer" } });
  await pending;
  assert.equal(cache.snapshot("profile"), null);
});

test("expired sessions clear previously loaded private panels", async () => {
  const cache = createPanelCache(async (panel) => panel === "library" ? { library: [first] } : { signIn: true });
  await cache.load("library");
  await cache.load("profile");
  assert.equal(cache.snapshot("library"), null);
  assert.equal(cache.snapshot("profile").signIn, true);
});

test("an old background response cannot overwrite an optimistic removal", async () => {
  const refresh = deferred();
  let requests = 0;
  const cache = createPanelCache(() => ++requests === 1 ? Promise.resolve({ library: [first, second] }) : refresh.promise);
  await cache.load("library");
  const pending = cache.load("library", true);
  cache.editLibrary(first, false).commit();
  refresh.resolve({ library: [first, second] });
  await pending;
  assert.deepEqual(cache.snapshot("library").library, [second]);
});

test("explicit retry reloads failures and unsubscribed listeners stop receiving updates", async () => {
  let requests = 0;
  let notifications = 0;
  const cache = createPanelCache(async () => ++requests === 1 ? { error: "Unavailable" } : { library: [first] });
  const unsubscribe = cache.subscribe(() => notifications++);
  await cache.load("library");
  unsubscribe();
  await cache.load("library", true);
  assert.equal(requests, 2);
  assert.equal(notifications, 1);
  assert.deepEqual(cache.snapshot("library").library, [first]);
});
