// @vitest-environment jsdom
import { afterEach, beforeEach, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { AccountPage } from "../src/screens/account/AccountScreen";
import { accountApi } from "../src/services/api/account/accountApi";

vi.mock("../src/services/api/account/accountApi", () => ({
  accountApi: { getProfile: vi.fn(), updateAvatar: vi.fn() },
}));
const profile = { id: 1, username: "test-user", phone: "0912345678", avatar: "https://images.example.com/old.webp" };
beforeEach(() => {
  vi.clearAllMocks();
  vi.mocked(accountApi.getProfile).mockResolvedValue(profile);
  Object.defineProperty(URL, "createObjectURL", { configurable: true, value: vi.fn(() => "blob:preview") });
  Object.defineProperty(URL, "revokeObjectURL", { configurable: true, value: vi.fn() });
});
afterEach(cleanup);
async function choose(file: File) {
  render(<AccountPage />);
  await screen.findByText("@test-user");
  fireEvent.change(screen.getByLabelText("Thay đổi ảnh đại diện"), { target: { files: [file] } });
}

it("previews selected image and displays the saved URL after update", async () => {
  const file = new File(["image"], "avatar.webp", { type: "image/webp" });
  vi.mocked(accountApi.updateAvatar).mockResolvedValue({ ...profile, avatar: "https://images.example.com/new.webp" });
  await choose(file);
  expect(screen.getByAltText("Ảnh đại diện").getAttribute("src")).toBe("blob:preview");
  fireEvent.click(screen.getByRole("button", { name: "Lưu ảnh đại diện" }));
  await screen.findByText("Đã cập nhật ảnh đại diện.");
  expect(accountApi.updateAvatar).toHaveBeenCalledWith(file, profile);
  expect(screen.getByAltText("Ảnh đại diện").getAttribute("src")).toBe("https://images.example.com/new.webp");
  expect(URL.revokeObjectURL).toHaveBeenCalledWith("blob:preview");
});

it("rejects unsupported file types without uploading", async () => {
  await choose(new File(["<svg/>"], "image.svg", { type: "image/svg+xml" }));
  expect(screen.getByRole("alert").textContent).toContain("JPG, PNG hoặc WebP");
  expect(accountApi.updateAvatar).not.toHaveBeenCalled();
  expect(URL.createObjectURL).not.toHaveBeenCalled();
});

it("rejects images above 5 MB", async () => {
  await choose(new File([new Uint8Array(5 * 1024 * 1024 + 1)], "large.png", { type: "image/png" }));
  expect(screen.getByRole("alert").textContent).toContain("tối đa 5 MB");
  expect(accountApi.updateAvatar).not.toHaveBeenCalled();
});

it("shows upload failure and retains preview for retry", async () => {
  vi.mocked(accountApi.updateAvatar).mockRejectedValue(new Error("Upload failed"));
  await choose(new File(["image"], "avatar.png", { type: "image/png" }));
  fireEvent.click(screen.getByRole("button", { name: "Lưu ảnh đại diện" }));
  await waitFor(() => expect(screen.getByRole("alert").textContent).toBe("Upload failed"));
  expect(screen.queryByText("Đã cập nhật ảnh đại diện.")).toBeNull();
  expect(screen.getByAltText("Ảnh đại diện").getAttribute("src")).toBe("blob:preview");
});
