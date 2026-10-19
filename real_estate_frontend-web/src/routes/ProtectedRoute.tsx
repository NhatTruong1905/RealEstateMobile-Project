import type { ReactNode } from "react";
import { Navigate, useLocation } from "react-router-dom";
import { session } from "../services/api/core/session";

export function ProtectedRoute({ children }: { children: ReactNode }) {
  const location = useLocation();

  return session.token ? (
    children
  ) : (
    <Navigate
      to={`/login?returnTo=${encodeURIComponent(location.pathname + location.search)}`}
      replace
    />
  );
}
