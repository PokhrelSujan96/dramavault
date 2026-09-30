import assert from "node:assert/strict";
import { test } from "node:test";
import { load } from "./runtime-loader.mjs";

const id = "12345678-1234-1234-1234-123456789abc";
const profile = { id, display_name: "Viewer", email: "viewer@example.com", avatar_url: null, coins: 8060, bonus_coins: 1400, vip_expires_at: null };
const history = { items: [{ episode_id: id, series_id: id, title: "A real series", episode_number: 1, thumbnail_url: "https://media.example.com/cover.jpg", position_seconds: 20, duration_seconds: 60 }], next_cursor: null };
const referral = { code: "ABC12345", invited: 2, purchased: 1, earned: 30, signup_reward: 5, purchase_reward: 20 };
const json = (value, status = 200) => new Response(JSON.stringify(value), { status });
const cookies = (token) => ({ "next/headers": { cookies: async () => ({ get: () => token ? { value: token } : undefined }) } });
const repository = (fetch, token = "private-token") => load("infrastructure/account/navigation-repository.ts", { fetch }, cookies(token));

test("signed-out panels never request private account data", async () => {
  let requests = 0;
  const { getNavigationData } = repository(async () => { requests++; }, null);
  for (const panel of ["profile", "library", "referral", "history"]) assert.equal((await getNavigationData(panel)).signIn, true);
  assert.equal(requests, 0);
});

test("profile and history use uncached authenticated requests and expose no token", async () => {
  const requests = [];
  const { getNavigationData } = repository(async (url, options) => {
    requests.push({ url, options });
    return json(url.includes("history") ? history : profile);
  });
  const result = await getNavigationData("profile");
  assert.equal(result.profile.coins, 8060);
  assert.equal(result.history[0].episode_number, 1);
  assert.equal(JSON.stringify(result).includes("private-token"), false);
  for (const { options } of requests) {
    assert.equal(options.cache, "no-store");
    assert.equal(options.redirect, "error");
    assert.equal(options.headers.Authorization, "Bearer private-token");
    assert.ok(options.signal instanceof AbortSignal);
  }
});

test("history failure preserves the profile without inventing history items", async () => {
  const { getNavigationData } = repository(async (url) => json(url.includes("history") ? {} : profile, url.includes("history") ? 503 : 200));
  const result = await getNavigationData("profile");
  assert.equal(result.profile.display_name, "Viewer");
  assert.equal(result.history, undefined);
});

test("expired sessions show a sign-in prompt", async () => {
  const { getNavigationData } = repository(async () => json({}, 401));
  assert.equal((await getNavigationData("library")).signIn, true);
  assert.equal((await getNavigationData("profile")).signIn, true);
});

test("referral uses the account code and reward amounts rather than screenshot values", async () => {
  const { getNavigationData } = repository(async () => json(referral));
  assert.deepEqual((await getNavigationData("referral")).referral, referral);
});

test("invalid data never becomes demo profile or referral data", async () => {
  for (const panel of ["profile", "referral", "library", "history"]) {
    const { getNavigationData } = repository(async () => json({}));
    const result = await getNavigationData(panel);
    assert.ok(result.error);
    assert.equal(result.profile, undefined);
    assert.equal(result.referral, undefined);
  }
});

test("invalid balances, unsafe artwork and malformed history IDs are handled", () => {
  const { parseProfile, parseReferral, parseHistory } = load("infrastructure/account/validate-navigation.ts");
  assert.throws(() => parseProfile({ ...profile, coins: -1 }), /Invalid profile/);
  assert.throws(() => parseReferral({ ...referral, earned: "30" }), /Invalid referral totals/);
  assert.equal(parseProfile({ ...profile, avatar_url: "javascript:alert(1)" }).avatar_url, null);
  assert.deepEqual(parseHistory({ items: [{ ...history.items[0], series_id: "../auth" }] }), []);
});
