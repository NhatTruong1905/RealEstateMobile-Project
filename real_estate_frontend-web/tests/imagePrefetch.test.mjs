import { test } from "node:test";
import assert from "node:assert/strict";
import { createImagePrefetcher, canPrefetchImages } from "../src/services/images/imagePrefetch.ts";

const tick = () => new Promise((resolve) => setImmediate(resolve));

test("limits concurrency, bounds waiting work, and deduplicates pending URLs", async () => {
  const requests = [];
  const enqueue = createImagePrefetcher((url) => new Promise((resolve) => requests.push({ url, resolve })));
  for (let index = 0; index < 20; index++) enqueue(`image-${index}`);
  enqueue("image-0");
  await tick();
  assert.deepEqual(requests.map(({ url }) => url), ["image-0", "image-1"]);
  for (let index = 0; index < 10; index++) {
    assert.ok(requests[index]);
    requests[index].resolve(true);
    await tick();
  }
  assert.equal(requests.length, 10);
});

test("retries failures, suppresses recent success, and expires bookkeeping", async () => {
  let time = 0;
  let calls = 0;
  const enqueue = createImagePrefetcher(async () => ++calls !== 1, () => time);
  enqueue("cover");
  await tick();
  enqueue("cover");
  await tick();
  assert.equal(calls, 2);
  enqueue("cover");
  await tick();
  assert.equal(calls, 2);
  time = 60_001;
  enqueue("cover");
  await tick();
  assert.equal(calls, 3);
});

test("a rejected load releases a slot and allows retry", async () => {
  let calls = 0;
  const enqueue = createImagePrefetcher(async () => {
    if (++calls === 1) throw new Error("offline");
    return true;
  });
  enqueue("cover");
  await tick();
  enqueue("cover");
  await tick();
  assert.equal(calls, 2);
});

test("respects data saver, slow connections, and offline state", () => {
  const original = Object.getOwnPropertyDescriptor(globalThis, "navigator");
  try {
    for (const value of [
      { onLine: false },
      { connection: { saveData: true } },
      { connection: { effectiveType: "2g" } },
      { connection: { effectiveType: "slow-2g" } },
    ]) {
      Object.defineProperty(globalThis, "navigator", { configurable: true, value });
      assert.equal(canPrefetchImages(), false);
    }
    Object.defineProperty(globalThis, "navigator", { configurable: true, value: { onLine: true } });
    assert.equal(canPrefetchImages(), true);
  } finally {
    if (original) Object.defineProperty(globalThis, "navigator", original);
    else delete globalThis.navigator;
  }
});
