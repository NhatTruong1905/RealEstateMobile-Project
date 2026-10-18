import { useEffect, useRef, useState } from "react";
import { Bookmark, ChevronDown, CircleUserRound, Menu } from "lucide-react";
import { Link, NavLink, useLocation } from "react-router-dom";
import { api } from "../services/api/client";
import { Logo } from "../components/brand/Logo";
import { useAuthenticated } from "../hooks/useAuthenticated";

export function Header() {
  const [open, setOpen] = useState(false);
  const propertyMenu = useRef<HTMLDetailsElement>(null);
  const authenticated = useAuthenticated();
  const location = useLocation();
  const propertyType = new URLSearchParams(location.search).get("typeId");

  function closeNavigation() {
    setOpen(false);
    propertyMenu.current?.removeAttribute("open");
  }

  useEffect(() => {
    if (authenticated) api.favorites().catch(() => {});
  }, [authenticated]);

  return (
    <header className="site-header">
      <div className="header-inner">
        <Logo />
        <button
          className="icon-button menu-button"
          onClick={() => setOpen(!open)}
          aria-expanded={open}
          aria-label="Mở menu"
        >
          <Menu />
        </button>
        <nav
          className={open ? "main-nav is-open" : "main-nav"}
          aria-label="Điều hướng chính"
        >
          <details className="property-nav-menu" ref={propertyMenu}>
            <summary className={location.pathname === "/properties" ? "active" : ""}>
              Bất động sản <ChevronDown />
            </summary>
            <div className="property-nav-submenu">
              <Link
                className={propertyType === "1" ? "active" : ""}
                to="/properties?typeId=1"
                onClick={closeNavigation}
              >
                Mua bán
              </Link>
              <Link
                className={propertyType === "2" ? "active" : ""}
                to="/properties?typeId=2"
                onClick={closeNavigation}
              >
                Cho thuê
              </Link>
            </div>
          </details>
          <NavLink to="/seller/post" onClick={closeNavigation}>Đăng tin</NavLink>
          <NavLink to="/faq" onClick={closeNavigation}>Hỗ trợ</NavLink>
        </nav>
        <div className="header-actions">
          <Link className="icon-button" to="/saved" aria-label="Tin đã lưu">
            <Bookmark />
          </Link>
          {authenticated ? (
            <Link className="account-link" to="/account">
              <CircleUserRound /> Tài khoản
            </Link>
          ) : (
            <Link className="text-link" to="/login">
              Đăng nhập
            </Link>
          )}
        </div>
      </div>
    </header>
  );
}
