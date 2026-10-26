// @vitest-environment jsdom
import { afterEach, beforeEach, expect, it, vi } from "vitest";
import { authApi } from "../src/services/api/auth/authApi";
import { request } from "../src/services/api/core/http";

beforeEach(() => { localStorage.clear(); vi.stubGlobal("fetch", vi.fn()); });
afterEach(() => vi.unstubAllGlobals());

it.each([
  [404, "Tài khoản không tồn tại. Vui lòng kiểm tra tên đăng nhập hoặc đăng ký tài khoản."],
  [401, "Tên đăng nhập hoặc mật khẩu không chính xác."],
])("uses login-specific messages for HTTP %s", async (status, message) => {
  vi.mocked(fetch).mockResolvedValue(new Response("Backend error", { status }));
  await expect(authApi.login(" buyer ", " pass ")).rejects.toMatchObject({ status, message });
  expect(JSON.parse(vi.mocked(fetch).mock.calls[0][1]!.body as string)).toEqual({ username: "buyer", password: " pass " });
});

it("normalizes registration at the API boundary without modifying passwords", async () => {
  vi.mocked(fetch).mockResolvedValue(new Response("{}"));
  await authApi.register({ fullname: " Nguyễn   An ", username: " buyer ", email: " buyer@gmail.com ", phone: " 0912 345 678 ", password: " secret123 " });
  expect(JSON.parse(vi.mocked(fetch).mock.calls[0][1]!.body as string)).toEqual({ fullname: "Nguyễn An", username: "buyer", email: "buyer@gmail.com", phone: "0912345678", password: " secret123 " });
});

it("preserves registration validation errors from the backend", async () => {
  vi.mocked(fetch).mockResolvedValue(new Response(JSON.stringify({ email: "Email đã được sử dụng." }), { status: 400 }));
  await expect(authApi.register({ fullname: "An", username: "buyer", email: "buyer@gmail.com", phone: "0912345678", password: "secret123" })).rejects.toMatchObject({ message: "Email đã được sử dụng." });
});

it("uses connection errors appropriate to authentication", async () => {
  vi.mocked(fetch).mockRejectedValue(new TypeError("Failed to fetch"));
  await expect(authApi.login("buyer", "secret123")).rejects.toMatchObject({ status: 0, message: "Không thể kết nối máy chủ. Vui lòng kiểm tra kết nối và thử lại." });
});

it("keeps the property-specific not-found message for property requests", async () => {
  vi.mocked(fetch).mockResolvedValue(new Response("Missing", { status: 404 }));
  await expect(request("/secure/properties/42")).rejects.toMatchObject({ message: "Không tìm thấy tin đăng." });
});
