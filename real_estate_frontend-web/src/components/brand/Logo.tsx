import { House } from "lucide-react";
import { Link } from "react-router-dom";

export function Logo() {
  return (
    <Link className="logo" to="/" aria-label="Nhà Việt — trang chủ">
      <span className="logo-mark">
        <House size={20} strokeWidth={1.8} />
      </span>
      <span>
        Nhà<em>Việt</em>
      </span>
    </Link>
  );
}
