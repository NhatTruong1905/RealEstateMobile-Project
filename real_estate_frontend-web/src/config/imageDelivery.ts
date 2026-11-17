// Trusted public image origin, without credentials or signed URLs.
const configuredOrigin = import.meta.env.VITE_IMAGE_ORIGIN as string | undefined;
export const imageOrigin = (() => {
  if (!configuredOrigin) return undefined;
  try {
    const url = new URL(configuredOrigin);
    return ["https:", "http:"].includes(url.protocol) ? url.origin : undefined;
  } catch {
    return undefined;
  }
})();
