import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { clearQueries, loadQuery, setQuery, snapshot, updateQueries } from "../lib/query-cache.ts";

beforeEach(() => clearQueries());

test("returning to a page reuses its cached records", async () => {
  let calls = 0;
  const fetcher = async () => { calls++; return { items: [1] }; };
  await loadQuery("/users", fetcher);
  await loadQuery("/users", fetcher);
  assert.equal(calls, 1);
  assert.deepEqual(snapshot("/users").data, { items: [1] });
});

test("simultaneous requests share one network call", async () => {
  let calls = 0;
  await Promise.all([loadQuery("/series", async () => { calls++; return [1]; }), loadQuery("/series", async () => { calls++; return [2]; })]);
  assert.equal(calls, 1);
});

test("failed optimistic changes restore the previous value", () => {
  setQuery("/coins", { coins: 10 });
  const rollback = updateQueries((key, data) => key === "/coins" ? { coins: 20 } : data);
  assert.deepEqual(snapshot("/coins").data, { coins: 20 });
  rollback();
  assert.deepEqual(snapshot("/coins").data, { coins: 10 });
});

test("a stale response cannot overwrite an optimistic change", async () => {
  let finish;
  const pending = loadQuery("/videos", () => new Promise((resolve) => { finish = resolve; }));
  setQuery("/videos", { status: "published" });
  finish({ status: "ready" });
  await pending;
  assert.deepEqual(snapshot("/videos").data, { status: "published" });
});

test("sign-out prevents outstanding responses from restoring private records", async () => {
  let finish;
  const pending = loadQuery("/private", () => new Promise((resolve) => { finish = resolve; }));
  clearQueries(); finish({ secret: true }); await pending;
  assert.equal(snapshot("/private").data, undefined);
});

test("rollback does not overwrite a newer server update", () => {
  setQuery("/balance", 10);
  const rollback = updateQueries((key, data) => key === "/balance" ? 20 : data);
  setQuery("/balance", 30); rollback();
  assert.equal(snapshot("/balance").data, 30);
});
