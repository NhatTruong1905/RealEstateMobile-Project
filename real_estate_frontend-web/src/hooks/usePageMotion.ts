import { useSyncExternalStore } from "react";

const motionQuery = "(prefers-reduced-motion: reduce)";
const subscribe = (notify: () => void) => {
  const media = window.matchMedia(motionQuery);
  media.addEventListener("change", notify);
  return () => media.removeEventListener("change", notify);
};
const getReducedMotion = () => window.matchMedia(motionQuery).matches;
export const isAuth = (path: string) => path === "/login" || path === "/register";

export function usePageMotion() {
  const reduced = useSyncExternalStore(subscribe, getReducedMotion, () => true);
  return !reduced && typeof document.startViewTransition === "function";
}
