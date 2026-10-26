// @vitest-environment jsdom
import { afterEach, beforeEach, expect, it, vi } from "vitest";
import { accountApi } from "../src/services/api/account/accountApi";
import { request } from "../src/services/api/core/http";
import { session } from "../src/services/api/core/session";
vi.mock("../src/services/api/core/http", () => ({ request: vi.fn(), isMockMode: false }));
const profile = { id: 7, username: "owner", phone: "0912345678", avatar: "https://images.example/old.webp" };
const file = new File(["image"], "avatar.webp", { type: "image/webp" });
beforeEach(() => { vi.resetAllMocks(); session.set("test-token"); });
afterEach(() => session.clear());
it("loads the current user's profile from the protected API", async () => {
  vi.mocked(request).mockResolvedValueOnce({ data: profile });
  await expect(accountApi.getProfile()).resolves.toEqual(profile);
  expect(request).toHaveBeenCalledWith("/secure/profile");
});
it("reports profile failures instead of returning mock data", async () => {
  vi.mocked(request).mockRejectedValueOnce(new Error("Offline"));
  await expect(accountApi.getProfile()).rejects.toThrow("Offline");
  vi.mocked(request).mockResolvedValueOnce({ data: null });
  await expect(accountApi.getProfile()).rejects.toThrow("Không tải được hồ sơ.");
});
it("sends the actual multipart fields then confirms the new profile URL", async () => {
  vi.mocked(request).mockResolvedValueOnce({ message: "Success" }).mockResolvedValueOnce({ data: { ...profile, avatar: "https://images.example/new.webp" } });
  const changed = vi.fn(); window.addEventListener("profile-change", changed);
  try {
    const saved = await accountApi.updateAvatar(file, profile);
    const body = vi.mocked(request).mock.calls[0][1]?.body as FormData;
    expect(body.get("file")).toBe(file); expect(body.get("username")).toBe("owner"); expect(body.get("phone")).toBe(profile.phone);
    expect(saved.avatar).toContain("new.webp"); expect(changed).toHaveBeenCalledOnce();
  } finally { window.removeEventListener("profile-change", changed); }
});
it.each([profile, { ...profile, avatar: "" }, { ...profile, id: 9, avatar: "https://images.example/new.webp" }])("does not confirm stale, missing or other-account avatars", async data => {
  vi.mocked(request).mockResolvedValueOnce({}).mockResolvedValueOnce({ data });
  await expect(accountApi.updateAvatar(file, profile)).rejects.toThrow("Chưa xác nhận");
});
it("ignores a late upload after logout and same-token login", async () => {
  let finish!: (result: unknown) => void;
  vi.mocked(request).mockImplementationOnce(() => new Promise(resolve => { finish = resolve; }));
  const pending = accountApi.updateAvatar(file, profile);
  session.clear(); session.set("test-token"); finish({});
  await expect(pending).rejects.toThrow("Phiên đăng nhập"); expect(request).toHaveBeenCalledTimes(1);
});
it("reports profile refetch failure instead of upload success", async () => {
  vi.mocked(request).mockResolvedValueOnce({}).mockRejectedValueOnce(new Error("Refetch failed"));
  await expect(accountApi.updateAvatar(file, profile)).rejects.toThrow("Refetch failed");
});
