// @vitest-environment jsdom
import { afterEach, beforeEach, expect, it, vi } from "vitest";
import { act, cleanup, fireEvent, render, screen, waitFor } from "@testing-library/react";
import { Link } from "react-router-dom";
import App from "../src/App";
import { session } from "../src/services/api/core/session";
import { request } from "../src/services/api/core/http";

vi.mock("../src/screens/properties/PropertiesScreen", () => ({
  PropertiesPage: () => <Link to="/properties/42">Open property 42</Link>,
}));
vi.mock("../src/screens/properties/PropertyDetailScreen", () => ({
  PropertyDetailPage: () => <div>Property 42 details</div>,
}));
vi.mock("../src/components/chat/ChatWidget", () => ({ ChatWidget: () => null }));

beforeEach(() => {
  localStorage.clear();
  sessionStorage.clear();
  window.history.replaceState({}, "", "/properties");
  vi.stubGlobal("fetch", vi.fn(async (url: string) => {
    if (url.endsWith("/auth/login")) return new Response(JSON.stringify({ token: "valid-token" }));
    if (url.endsWith("/secure/profile")) return new Response(JSON.stringify({ data: { id: 1, username: "buyer" } }));
    return new Response(JSON.stringify({ data: [] }));
  }));
});
afterEach(() => { cleanup(); vi.unstubAllGlobals(); });

it("shows login to guests and returns to the selected property after login", async () => {
  render(<App />);
  expect(screen.getByRole("link", { name: "Đăng nhập" }).getAttribute("href")).toBe("/login");
  expect(screen.queryByRole("link", { name: "Tài khoản" })).toBeNull();
  fireEvent.click(screen.getByRole("link", { name: "Open property 42" }));
  await screen.findByRole("button", { name: "Đăng nhập" });
  expect(window.location.pathname).toBe("/login");
  expect(new URLSearchParams(window.location.search).get("returnTo")).toBe("/properties/42");
  expect(screen.queryByText("Property 42 details")).toBeNull();
  fireEvent.change(screen.getByLabelText("Tên đăng nhập"), { target: { value: "buyer" } });
  fireEvent.change(screen.getByLabelText("Mật khẩu"), { target: { value: "secret123" } });
  fireEvent.click(screen.getByRole("button", { name: "Đăng nhập" }));
  await screen.findByText("Property 42 details");
  expect(window.location.pathname).toBe("/properties/42");
  await screen.findByRole("link", { name: "Tài khoản của buyer" });
});

it("redirects a direct detail URL to login while preserving its query", async () => {
  window.history.replaceState({}, "", "/properties/42?source=saved");
  render(<App />);
  await screen.findByRole("button", { name: "Đăng nhập" });
  expect(new URLSearchParams(window.location.search).get("returnTo")).toBe("/properties/42?source=saved");
});

it("replaces the account link with login when the server rejects the session", async () => {
  session.set("expired-token");
  vi.mocked(fetch).mockResolvedValue(new Response("{}", { status: 401 }));
  render(<App />);
  await screen.findByRole("link", { name: "Đăng nhập" });
  expect(session.token).toBeNull();
  expect(screen.queryByRole("link", { name: /Tài khoản/ })).toBeNull();
});

it("redirects an open detail page when its session is cleared", async () => {
  session.set("valid-token");
  window.history.replaceState({}, "", "/properties/42");
  render(<App />);
  await screen.findByRole("link", { name: "Tài khoản của buyer" });
  act(() => session.clear());
  await screen.findByRole("button", { name: "Đăng nhập" });
  expect(new URLSearchParams(window.location.search).get("returnTo")).toBe("/properties/42");
});

it("does not clear a newer login when an old request returns 401", async () => {
  let finish!: (response: Response) => void;
  vi.mocked(fetch).mockImplementationOnce(() => new Promise((resolve) => { finish = resolve; }));
  session.set("same-token");
  const pending = request("/secure/profile");
  const rejected = expect(pending).rejects.toMatchObject({ status: 401 });
  session.clear();
  session.set("same-token");
  finish(new Response("{}", { status: 401 }));
  await rejected;
  await waitFor(() => expect(session.token).toBe("same-token"));
});
