import type { ReactNode } from "react";
import { Navigate, useLocation } from "react-router-dom";
import { useAuthenticated } from "../hooks/useAuthenticated";

export function ProtectedRoute({ children }: { children: ReactNode }) {
  const location = useLocation();
  const authenticated = useAuthenticated();

  return authenticated ? (
    children
  ) : (
    <Navigate
      to={`/login?returnTo=${encodeURIComponent(location.pathname + location.search)}`}
      replace
    />
  );
}
