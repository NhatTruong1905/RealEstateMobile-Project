import {
  Building2,
  ChevronLeft,
  CircleUserRound,
  House,
  Upload,
} from "lucide-react";
import { Link, NavLink, Outlet } from "react-router-dom";
import { Logo } from "../components/brand/Logo";

export function SellerLayout() {
  return (
    <div className="seller-shell">
      <aside className="seller-sidebar">
        <Logo />
        <nav>
          <NavLink to="/seller/overview">
            <Building2 /> Tổng quan
          </NavLink>
          <NavLink to="/seller/properties">
            <House /> Tin đăng
          </NavLink>
          <NavLink to="/seller/post">
            <Upload /> Đăng tin mới
          </NavLink>
          <NavLink to="/seller/customers">
            <CircleUserRound /> Khách hàng
          </NavLink>
        </nav>
        <Link className="back-link" to="/">
          <ChevronLeft /> Về trang chủ
        </Link>
      </aside>
      <main className="seller-main">
        <Outlet />
      </main>
    </div>
  );
}
