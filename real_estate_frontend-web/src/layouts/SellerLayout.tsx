import {
  Building2,
  ChevronLeft,
  CircleUserRound,
  House,
  Upload,
} from "lucide-react";
import { Link, NavLink } from "../components/ui/Navigation";
import { RouteContent } from "../components/ui/RouteContent";
import { Logo } from "../components/brand/Logo";

const sellerNavigation = [
  { to: "/seller/overview", label: "Tổng quan", icon: Building2 },
  { to: "/seller/properties", label: "Tin đăng", icon: House },
  { to: "/seller/post", label: "Đăng tin mới", icon: Upload },
  { to: "/seller/customers", label: "Khách hàng", icon: CircleUserRound },
];

export function SellerLayout() {
  return (
    <div className="seller-shell">
      <aside className="seller-sidebar">
        <Logo />
        <nav aria-label="Khu vực người bán">
          {sellerNavigation.map(({ to, label, icon: Icon }) => (
            <NavLink key={to} to={to}>
              {({ isActive }) => <>
                {isActive && <span className="seller-nav-indicator" aria-hidden="true" />}
                <span className="seller-nav-content" style={{ viewTransitionName: `seller-nav-${to.split("/").at(-1)}` }}>
                  <Icon aria-hidden="true" /><span className="seller-nav-label">{label}</span>
                </span>
              </>}
            </NavLink>
          ))}
        </nav>
        <Link className="back-link" to="/">
          <ChevronLeft /> Về trang chủ
        </Link>
      </aside>
      <main className="seller-main">
        <RouteContent />
      </main>
    </div>
  );
}
