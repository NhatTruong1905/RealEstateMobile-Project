import { useEffect, useRef, useState } from "react";
import { Bookmark, ChevronDown, CircleUserRound, Menu } from "lucide-react";
import { Link, NavLink, useLocation } from "react-router-dom";
import { accountApi } from "../services/api/account/accountApi";
import { session } from "../services/api/core/session";
import { favoriteApi } from "../services/api/favorite/favoriteApi";
import { Logo } from "../components/brand/Logo";
import { useAuthenticated } from "../hooks/useAuthenticated";
import type { UserProfile } from "../types";

export function Header() {
  const [open, setOpen] = useState(false);
  const [profileState, setProfileState] = useState<{
    token: string;
    profile: UserProfile | null;
  } | null>(null);
  const [failedAvatarUrl, setFailedAvatarUrl] = useState("");
  const [profileVersion, setProfileVersion] = useState(0);
  const propertyMenu = useRef<HTMLDetailsElement>(null);
  const authenticated = useAuthenticated();
  const location = useLocation();
  const propertyType = new URLSearchParams(location.search).get("typeId");
  const currentToken = session.token || "";
  const profile = profileState?.token === currentToken ? profileState.profile : null;

  function closeNavigation() {
    setOpen(false);
    propertyMenu.current?.removeAttribute("open");
  }

  useEffect(() => {
    const refresh = () => setProfileVersion((version) => version + 1);
    window.addEventListener("profile-change", refresh);
    return () => window.removeEventListener("profile-change", refresh);
  }, []);

  useEffect(() => {
    if (!authenticated) {
      return;
    }

    let active = true;
    const token = session.token || "";
    favoriteApi.list().catch(() => {});
    accountApi.getProfile()
      .then((user) => {
        if (active) {
          setProfileState({ token, profile: user });
        }
      })
      .catch(() => {
        if (active) setProfileState({ token, profile: null });
      });

    return () => {
      active = false;
    };
  }, [authenticated, profileVersion]);

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
            <Link
              className="account-link"
              to="/account"
              aria-label={profile?.username ? `Tài khoản của ${profile.username}` : "Tài khoản"}
              title={profile?.username}
            >
              <span className="account-avatar" aria-hidden="true">
                {profile?.avatar && profile.avatar !== failedAvatarUrl ? (
                  <img
                    src={profile.avatar}
                    alt=""
                    width={30}
                    height={30}
                    onError={() => setFailedAvatarUrl(profile.avatar || "")}
                  />
                ) : (
                  <CircleUserRound />
                )}
              </span>
              <span className="account-username">
                {profile?.username || "Tài khoản"}
              </span>
            </Link>
          ) : (
            <Link className="header-login" to="/login">
              Đăng nhập
            </Link>
          )}
        </div>
      </div>
    </header>
  );
}
