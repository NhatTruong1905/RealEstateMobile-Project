import { useCallback } from "react";
import { useLocation, useNavigate as useRouterNavigate } from "react-router-dom";
import type { NavigateFunction, NavigateOptions, To } from "react-router-dom";
import { isAuth, usePageMotion } from "./usePageMotion";

export function useNavigate(): NavigateFunction {
  const navigate = useRouterNavigate();
  const enabled = usePageMotion();
  const { pathname } = useLocation();
  const navigateWithMotion = useCallback((to: To | number, options?: NavigateOptions) => {
    if (typeof to === "number") return navigate(to);
    const target = typeof to === "string" ? to.split(/[?#]/)[0] : to.pathname || pathname;
    return navigate(to, { viewTransition: enabled && !(isAuth(pathname) && isAuth(target)), ...options });
  }, [navigate, enabled, pathname]);
  return navigateWithMotion as NavigateFunction;
}
