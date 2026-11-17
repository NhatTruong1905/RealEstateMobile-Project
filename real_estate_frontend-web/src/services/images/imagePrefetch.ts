type Connection = { saveData?: boolean; effectiveType?: string };

export function canPrefetchImages(): boolean {
  if (typeof navigator === "undefined") return false;
  const connection = (navigator as Navigator & { connection?: Connection }).connection;
  return navigator.onLine !== false && !connection?.saveData &&
    !["slow-2g", "2g"].includes(connection?.effectiveType || "");
}

function loadImage(url: string): Promise<boolean> {
  return new Promise((resolve) => {
    const image = new Image();
    const finish = (success: boolean) => {
      clearTimeout(timer);
      image.onload = image.onerror = null;
      if (!success) image.removeAttribute("src");
      resolve(success);
    };
    const timer = setTimeout(() => finish(false), 15_000);
    image.onload = () => finish(true);
    image.onerror = () => finish(false);
    image.decoding = "async";
    image.fetchPriority = "low";
    image.src = url;
  });
}

// This only schedules requests. The browser's HTTP cache owns the image bytes.
// Keep bookkeeping bounded; failed requests may be retried on the next intent.
export function createImagePrefetcher(load = loadImage, now = Date.now) {
  const pending = new Set<string>();
  const completed = new Map<string, number>();
  const queue: string[] = [];
  let active = 0;

  function drain() {
    while (active < 2 && queue.length) {
      const url = queue.shift()!;
      active++;
      void Promise.resolve().then(() => load(url)).then((success) => {
        if (!success) return;
        completed.set(url, now());
        if (completed.size > 48) completed.delete(completed.keys().next().value!);
      }).catch(() => {
        // Speculative loading must never surface an unhandled rejection.
      }).finally(() => {
        pending.delete(url);
        active--;
        drain();
      });
    }
  }

  return (url: string) => {
    if (!url || pending.has(url) || queue.length >= 8) return;
    const timestamp = completed.get(url);
    if (timestamp !== undefined && now() - timestamp < 60_000) return;
    completed.delete(url);
    pending.add(url);
    queue.push(url);
    drain();
  };
}

const enqueue = createImagePrefetcher();

export function prefetchImage(url: string) {
  if (typeof Image !== "undefined" && canPrefetchImages()) enqueue(url);
}
