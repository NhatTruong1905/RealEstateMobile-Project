import { useState } from "react";
import type { SubmitEvent } from "react";
import { ChevronLeft, LoaderCircle } from "lucide-react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { authApi } from "../../services/api/auth/authApi";
import { favoriteApi } from "../../services/api/favorite/favoriteApi";
import { Logo } from "../../components/brand/Logo";
import { normalizeAuthField } from "../../services/api/auth/normalizeAuth";

export function AuthPage({ mode }: { mode: "login" | "register" }) {
  return <AuthForm key={mode} mode={mode} />;
}

function AuthForm({ mode }: { mode: "login" | "register" }) {
  const navigate = useNavigate();
  const [search] = useSearchParams();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [emailError, setEmailError] = useState("");
  const [usernameError, setUsernameError] = useState("");
  const [errorField, setErrorField] = useState("");
  const returnQuery = search.toString();
  const switchPath = `${mode === "login" ? "/register" : "/login"}${returnQuery ? `?${returnQuery}` : ""}`;
  async function submit(e: SubmitEvent<HTMLFormElement>) {
    e.preventDefault();
    if (busy) return;
    setError("");
    setErrorField("");
    setUsernameError("");
    setEmailError("");
    const form = e.currentTarget;
    for (const input of Array.from(form.elements)) {
      if (input instanceof HTMLInputElement) input.value = normalizeAuthField(input.name, input.value);
    }
    const data = Object.fromEntries(new FormData(e.currentTarget));
    const fail = (name: string, message: string) => {
      setErrorField(name);
      if (name === "username") setUsernameError(message);
      else if (name === "email") setEmailError(message);
      else setError(message);
      (form.elements.namedItem(name) as HTMLInputElement | null)?.focus();
    };
    if (mode === "register" && !data.fullname) {
      fail("fullname", "Vui lòng nhập họ và tên.");
      return;
    }
    if (!data.username) {
      fail("username", "Vui lòng nhập tên đăng nhập.");
      return;
    }
    if (/\s/u.test(String(data.username))) {
      fail("username", "Tên đăng nhập không được chứa khoảng trắng.");
      return;
    }
    if (mode === "register") {
      if (String(data.username).length < 3) {
        fail("username", "Tên đăng nhập phải có ít nhất 3 ký tự.");
        return;
      }
      if (!/^0[0-9]{9}$/.test(String(data.phone))) {
        fail("phone", "Số điện thoại phải có đúng 10 chữ số và bắt đầu bằng số 0.");
        return;
      }
      if (!/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@gmail\.com$/.test(String(data.email))) {
        fail("email", data.email ? "Vui lòng nhập địa chỉ email có đuôi @gmail.com." : "Vui lòng nhập email.");
        return;
      }
    }
    if (!data.password) {
      fail("password", "Vui lòng nhập mật khẩu.");
      return;
    }
    if (mode === "register") {
      if (String(data.password).length < 6) {
        fail("password", "Mật khẩu phải có ít nhất 6 ký tự.");
        return;
      }
      if (!data.confirmPassword) {
        fail("confirmPassword", "Vui lòng xác nhận mật khẩu.");
        return;
      }
      if (data.password !== data.confirmPassword) {
        fail("confirmPassword", "Mật khẩu xác nhận không khớp. Vui lòng nhập lại.");
        return;
      }
    }
    setBusy(true);
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
        <form className="auth-form" onSubmit={submit} key={mode} noValidate
          onBlurCapture={(event) => {
            if (event.target instanceof HTMLInputElement) {
              event.target.value = normalizeAuthField(event.target.name, event.target.value);
            }
          }}
          onChangeCapture={() => { setError(""); setErrorField(""); }}
        >
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
            <div id="auth-form-error" className="form-error" role="alert">
              {error}
            </div>
          )}
          {mode === "register" && (
            <label>
              Họ và tên
              <input name="fullname" required autoComplete="name" placeholder="Full name"
                aria-invalid={errorField === "fullname"}
                aria-describedby={errorField === "fullname" ? "auth-form-error" : undefined} />
            </label>
          )}
          <label>
            Tên đăng nhập
            <input
              name="username"
              required
              minLength={3}
              placeholder="Username"
              autoComplete="username"
              aria-invalid={Boolean(usernameError)}
              aria-describedby={usernameError ? "auth-username-error" : undefined}
              onChange={(event) => {
                if (mode === "register") {
                  const username = normalizeAuthField("username", event.currentTarget.value);
                  setUsernameError(/\s/u.test(username)
                    ? "Tên đăng nhập không được chứa khoảng trắng."
                    : username.length < 3
                    ? "Tên đăng nhập phải có ít nhất 3 ký tự."
                    : "");
                } else setUsernameError("");
              }}
            />
          </label>
          {usernameError && (
            <div id="auth-username-error" className="form-error" role="alert">
              {usernameError}
            </div>
          )}
          {mode === "register" && (
            <>
              <label>
                Email
                <input
                  type="email"
                  name="email"
                  required
                  pattern=".+@gmail[.]com"
                  title="Vui lòng nhập email có đuôi @gmail.com"
                  placeholder="name@gmail.com"
                  autoComplete="email"
                  aria-invalid={Boolean(emailError)}
                  aria-describedby={emailError ? "register-email-error" : undefined}
                  onBlur={(event) => {
                    const input = event.currentTarget;
                    setEmailError(input.value && !input.validity.valid
                      ? "Vui lòng nhập địa chỉ email hợp lệ có đuôi @gmail.com."
                      : "");
                  }}
                  onChange={(event) => {
                    if (emailError) {
                      const email = normalizeAuthField("email", event.currentTarget.value);
                      setEmailError(/^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@gmail\.com$/.test(email)
                        ? ""
                        : "Vui lòng nhập địa chỉ email hợp lệ có đuôi @gmail.com.");
                    }
                  }}
                />
              </label>
              {emailError && (
                <div id="register-email-error" className="form-error" role="alert">
                  {emailError}
                </div>
              )}
              <label>
                Số điện thoại
                <input
                  type="tel"
                  name="phone"
                  aria-invalid={errorField === "phone"}
                  aria-describedby={errorField === "phone" ? "auth-form-error" : undefined}
                  inputMode="numeric"
                  maxLength={10}
                  placeholder="0912345678"
                  title="Số điện thoại gồm 10 chữ số, bắt đầu bằng số 0"
                  onInput={(event) => {
                    const input = event.currentTarget;
                    const digits = input.value.replace(/[^0-9]/g, "");
                    input.value = digits.startsWith("0") ? digits.slice(0, 10) : "";
                  }}
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
              placeholder={mode === "register" ? "Password (at least 6 characters)" : "Password"}
              name="password"
              required
              minLength={6}
              aria-invalid={errorField === "password"}
              aria-describedby={errorField === "password" ? "auth-form-error" : undefined}
              autoComplete={
                mode === "login" ? "current-password" : "new-password"
              }
            />
          </label>
          {mode === "register" && (
            <label>
              Xác nhận mật khẩu
              <input
                type="password"
                name="confirmPassword"
                required
                minLength={6}
                aria-invalid={errorField === "confirmPassword"}
                aria-describedby={errorField === "confirmPassword" ? "auth-form-error" : undefined}
                autoComplete="new-password"
                placeholder="Confirm password"
              />
            </label>
          )}
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

