import { useSyncExternalStore } from "react";
import { session } from "../services/api/core/session";

function hasActiveSession() {
  const parts = session.token?.split(".");
  if (parts?.length !== 3 || parts.some((part) => !part)) return false;

  try {
    const { exp } = JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")));
    return typeof exp === "number" && Number.isFinite(exp) && exp > Date.now() / 1000;
  } catch {
    return false;
  }
}

function subscribe(sync: () => void) {
  addEventListener("session-change", sync);
  return () => removeEventListener("session-change", sync);
}

export function useAuthenticated() {
  return useSyncExternalStore(subscribe, hasActiveSession);
}
