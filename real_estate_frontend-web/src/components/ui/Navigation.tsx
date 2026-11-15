import {
  Link as RouterLink,
  NavLink as RouterNavLink,
  useLocation,
  useResolvedPath,
} from "react-router-dom";
import type { LinkProps, NavLinkProps } from "react-router-dom";
import { isAuth, usePageMotion } from "../../hooks/usePageMotion";


export function Link(props: LinkProps) {
  const { pathname } = useLocation();
  const target = useResolvedPath(props.to);
  const enabled = usePageMotion() && !(isAuth(pathname) && isAuth(target.pathname));
  return <RouterLink {...props} viewTransition={props.viewTransition ?? enabled} />;
}

export function NavLink(props: NavLinkProps) {
  const enabled = usePageMotion();
  return <RouterNavLink {...props} viewTransition={props.viewTransition ?? enabled} />;
}

