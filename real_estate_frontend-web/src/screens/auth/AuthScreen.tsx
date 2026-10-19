import { useState } from "react";
import type { SubmitEvent } from "react";
import { ChevronLeft, LoaderCircle } from "lucide-react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { authApi } from "../../services/api/auth/authApi";
import { favoriteApi } from "../../services/api/favorite/favoriteApi";
import { Logo } from "../../components/brand/Logo";

export function AuthPage({ mode }: { mode: "login" | "register" }) {
  const navigate = useNavigate();
  const [search] = useSearchParams();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const returnQuery = search.toString();
  const switchPath = `${mode === "login" ? "/register" : "/login"}${returnQuery ? `?${returnQuery}` : ""}`;
  async function submit(e: SubmitEvent<HTMLFormElement>) {
    e.preventDefault();
    setBusy(true);
    setError("");
    const data = Object.fromEntries(new FormData(e.currentTarget));
    try {
      if (mode === "login") {
        await authApi.login(String(data.username), String(data.password));
        const pendingProperty = Number(search.get("saveProperty"));
        if (pendingProperty) await favoriteApi.set(pendingProperty, true);
        navigate(search.get("returnTo") || "/");
      } else {
        await authApi.register({
          fullname: String(data.fullname),
          username: String(data.username),
          password: String(data.password),
          email: String(data.email),
          phone: String(data.phone),
        });
        navigate(`/login${returnQuery ? `?${returnQuery}` : ""}`);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Có lỗi xảy ra");
    } finally {
      setBusy(false);
    }
  }
  return (
    <div className={mode === "register" ? "auth-page auth-register" : "auth-page auth-login"}>
      <div className="auth-art">
        <div className="auth-art-copy">
          <Logo />
          <p className="display-quote" key={mode}>
            {mode === "login"
              ? "“Một không gian tốt mở ra một chương sống mới.”"
              : "“Bắt đầu hành trình tìm nơi thuộc về bạn.”"}
          </p>
          <span>Nhà Việt · 2026</span>
        </div>
      </div>
      <div className="auth-form-wrap">
        <Link className="back-link" to="/">
          <ChevronLeft /> Về trang chủ
        </Link>
        <form className="auth-form" onSubmit={submit} key={mode}>
          <span className="eyebrow">
            {mode === "login" ? "Chào mừng trở lại" : "Bắt đầu với Nhà Việt"}
          </span>
          <h1>{mode === "login" ? "Đăng nhập" : "Tạo tài khoản"}</h1>
          <p>
            {mode === "login"
              ? "Quản lý tin đã lưu và kết nối với chủ nhà."
              : "Lưu lựa chọn, liên hệ và đăng tin bất động sản."}
          </p>
          {error && (
            <div className="form-error" role="alert">
              {error}
            </div>
          )}
          {mode === "register" && (
            <label>
              Họ và tên
              <input name="fullname" required autoComplete="name" />
            </label>
          )}
          <label>
            Tên đăng nhập
            <input
              name="username"
              required
              minLength={3}
              autoComplete="username"
            />
          </label>
          {mode === "register" && (
            <>
              <label>
                Email
                <input type="email" name="email" autoComplete="email" />
              </label>
              <label>
                Số điện thoại
                <input
                  name="phone"
                  required
                  pattern="0[0-9]{9}"
                  autoComplete="tel"
                />
              </label>
            </>
          )}
          <label>
            Mật khẩu
            <input
              type="password"
              name="password"
              required
              minLength={6}
              autoComplete={
                mode === "login" ? "current-password" : "new-password"
              }
            />
          </label>
          {mode === "login" && (
            <Link className="forgot-link" to="/forgot-password">
              Quên mật khẩu?
            </Link>
          )}
          <button className="button button-primary full" disabled={busy}>
            {busy ? (
              <>
                <LoaderCircle className="spin" /> Đang xử lý
              </>
            ) : mode === "login" ? (
              "Đăng nhập"
            ) : (
              "Tạo tài khoản"
            )}
          </button>
          <p className="auth-switch">
            {mode === "login" ? "Chưa có tài khoản?" : "Đã có tài khoản?"}{" "}
            <Link to={switchPath}>
              {mode === "login" ? "Đăng ký" : "Đăng nhập"}
            </Link>
          </p>
        </form>
      </div>
    </div>
  );
}

