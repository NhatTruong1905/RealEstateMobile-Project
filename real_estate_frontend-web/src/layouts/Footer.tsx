import { Link } from "react-router-dom";
import { Logo } from "../components/brand/Logo";

export function Footer() {
  return (
    <footer className="site-footer">
      <div className="footer-grid">
        <div>
          <Logo />
          <p>Nền tảng tìm kiếm và đăng tin bất động sản dành cho người Việt.</p>
        </div>
        <div>
          <h3>Khám phá</h3>
          <Link to="/properties">Tin bất động sản</Link>
          <Link to="/saved">Tin đã lưu</Link>
          <Link to="/seller/overview">Dành cho người bán</Link>
        </div>
        <div>
          <h3>Hỗ trợ</h3>
          <Link to="/faq">Câu hỏi thường gặp</Link>
          <Link to="/terms">Điều khoản</Link>
          <Link to="/privacy">Quyền riêng tư</Link>
        </div>
        <div>
          <h3>Liên hệ</h3>
          <a href="mailto:tn696199@gmail.com">tn696199@gmail.com</a>
          <p>
            Nếu cần hợp tác, hãy liên hệ với tôi qua số điện thoại
            <a className="footer-contact-link" href="tel:0967294349">
              0967 294 349
            </a>
            .
          </p>
        </div>
      </div>
      <div className="footer-bottom">
        <span>© 2026 Nhà Việt</span>
        <span>
          Sản phẩm được phát triển bởi <strong>NhatTruong1905</strong>
        </span>
      </div>
    </footer>
  );
}
