import { useLayoutEffect, useRef } from "react";
import { Outlet, useLocation } from "react-router-dom";

export function RouteContent() {
  const { pathname } = useLocation();
  const content = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    if (window.matchMedia?.("(prefers-reduced-motion: reduce)").matches || typeof document.startViewTransition === "function") return;
    const animation = content.current?.animate?.(
      [{ opacity: 0.4, transform: "translateY(8px)" }, { opacity: 1, transform: "translateY(0)" }],
      { duration: 240, easing: "cubic-bezier(0.16, 1, 0.3, 1)" },
    );
    return () => animation?.cancel();
  }, [pathname]);
  return <div ref={content} className="route-content"><Outlet /></div>;
}

