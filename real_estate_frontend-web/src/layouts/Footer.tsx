import { Link } from "../components/ui/Navigation";
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
        <div className="footer-contact">
          <h3>Liên hệ</h3>
          <div>
            <p>Hỗ trợ khách hàng</p>
            <a href="mailto:support@nhtr.id.vn">support@nhtr.id.vn</a>
          </div>
          <div>
            <p>Liên hệ hợp tác</p>
            <a href="tel:0967294349">0967 294 349</a>
          </div>
        </div>
      </div>
      <div className="footer-bottom">
        <span>© 2026 Nhà Thật</span>
        <span>
          Sản phẩm được phát triển bởi <strong>NhatTruong1905</strong>
        </span>
      </div>
    </footer>
  );
}
