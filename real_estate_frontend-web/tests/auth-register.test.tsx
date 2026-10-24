// @vitest-environment jsdom
import { afterEach, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { AuthPage } from "../src/screens/auth/AuthScreen";
import { authApi } from "../src/services/api/auth/authApi";
vi.mock("../src/services/api/auth/authApi", () => ({ authApi: { register: vi.fn(), login: vi.fn() } }));
afterEach(() => { cleanup(); vi.clearAllMocks(); });
function setup() {
  const view = render(<MemoryRouter><AuthPage mode="register" /></MemoryRouter>);
  const form = view.container.querySelector("form")!;
  const field = (name: string) => form.elements.namedItem(name) as HTMLInputElement;
  for (const [name, value] of Object.entries({ fullname: "Nguyen Van An", username: "nguyenvanan", email: "an@gmail.com", phone: "0912345678", password: "secret123", confirmPassword: "secret123" })) {
    fireEvent.change(field(name), { target: { value } });
  }
  return { form, field };
}
it("filters phone letters, rejects nonzero start and limits pasted digits", () => {
  const { field } = setup();
  fireEvent.input(field("phone"), { target: { value: "09ab12345678999" } });
  expect(field("phone").value).toBe("0912345678");
  fireEvent.input(field("phone"), { target: { value: "91234" } });
  expect(field("phone").value).toBe("");
});
it.each(["an@yahoo.com", "an@gmail.com.evil", "an@gmailxcom"])("rejects email %s", (email) => {
  const { form, field } = setup();
  fireEvent.change(field("email"), { target: { value: email } });
  expect(field("email").checkValidity()).toBe(false);
  fireEvent.submit(form);
  expect(authApi.register).not.toHaveBeenCalled();
});
it("shows email error on blur and clears it after correction", () => {
  const { field } = setup();
  expect(screen.queryByText("Chỉ sử dụng địa chỉ email có đuôi @gmail.com.")).toBeNull();
  fireEvent.change(field("email"), { target: { value: "an@yahoo.com" } });
  expect(screen.queryByRole("alert")).toBeNull();
  fireEvent.blur(field("email"));
  expect(screen.getByRole("alert").textContent).toContain("@gmail.com");
  expect(field("email").getAttribute("aria-invalid")).toBe("true");
  fireEvent.change(field("email"), { target: { value: "an@gmail.com" } });
  expect(screen.queryByRole("alert")).toBeNull();
  expect(field("email").getAttribute("aria-invalid")).toBe("false");
  expect(field("fullname").placeholder).toBe("Full name");
  expect(field("username").placeholder).toBe("Username");
  expect(field("email").placeholder).toBe("name@gmail.com");
  expect(field("confirmPassword").placeholder).toBe("Confirm password");
});
it("immediately validates username length while typing", () => {
  const { field } = setup();
  fireEvent.change(field("username"), { target: { value: "ab" } });
  expect(screen.getByRole("alert").textContent).toContain("ít nhất 3 ký tự");
  expect(field("username").getAttribute("aria-invalid")).toBe("true");
  fireEvent.change(field("username"), { target: { value: "abc" } });
  expect(screen.queryByRole("alert")).toBeNull();
  expect(field("username").getAttribute("aria-invalid")).toBe("false");
});
it("rejects short phone and mismatched password", () => {
  const { form, field } = setup();
  fireEvent.change(field("phone"), { target: { value: "0912" } });
  fireEvent.submit(form);
  expect(screen.getByRole("alert").textContent).toContain("10 chữ số");
  fireEvent.change(field("phone"), { target: { value: "0912345678" } });
  fireEvent.change(field("confirmPassword"), { target: { value: "different" } });
  fireEvent.submit(form);
  expect(screen.getByRole("alert").textContent).toContain("không khớp");
  expect(authApi.register).not.toHaveBeenCalled();
});
it("submits valid registration without confirmation in payload", async () => {
  vi.mocked(authApi.register).mockResolvedValue(undefined);
  const { form } = setup();
  fireEvent.submit(form);
  await waitFor(() => expect(authApi.register).toHaveBeenCalledWith({ fullname: "Nguyen Van An", username: "nguyenvanan", email: "an@gmail.com", phone: "0912345678", password: "secret123" }));
});
