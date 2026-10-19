import { useEffect, useState } from "react";
import { session } from "../services/api/core/session";

export function useAuthenticated() {
  const [authenticated, setAuthenticated] = useState(Boolean(session.token));

  useEffect(() => {
    const sync = () => setAuthenticated(Boolean(session.token));
    addEventListener("session-change", sync);
    return () => removeEventListener("session-change", sync);
  }, []);

  return authenticated;
}
