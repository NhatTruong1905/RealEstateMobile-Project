// @vitest-environment jsdom
import { afterEach, beforeEach, expect, it, vi } from "vitest";
import { act, cleanup, fireEvent, render, screen } from "@testing-library/react";
import { ChatWidget } from "../src/components/chat/ChatWidget";
import { session } from "../src/services/api/core/session";
import { chatApi } from "../src/services/api/chat/chatApi";
import { useAuthenticated } from "../src/hooks/useAuthenticated";
import { favoriteApi } from "../src/services/api/favorite/favoriteApi";
import { request } from "../src/services/api/core/http";

vi.mock("../src/services/api/chat/chatApi", () => ({ chatApi: { streamAnswer: vi.fn() } }));
vi.mock("../src/services/api/core/http", () => ({ request: vi.fn(), isMockMode: false }));
beforeEach(() => {
  localStorage.clear();
  sessionStorage.clear();
  Object.defineProperty(HTMLElement.prototype, "scrollIntoView", {
    configurable: true, value: vi.fn(),
  });
});
afterEach(() => { cleanup(); vi.restoreAllMocks(); });

it("clears all app session data and JWT from both stores", () => {
  for (const storage of [localStorage, sessionStorage]) {
    storage.setItem("real-estate-web-token", "old-token");
    storage.setItem("real-estate-web-chat-history", "private chat");
    storage.setItem("real-estate-web-favorites", "[1]");
    storage.setItem("other-app", "keep");
  }
  session.clear();
  expect(session.token).toBeNull();
  for (const storage of [localStorage, sessionStorage]) {
    expect(storage.length).toBe(1);
    expect(storage.getItem("other-app")).toBe("keep");
  }
});

it("resets live chatbot state and prevents late response from restoring history", async () => {
  let finish!: () => void;
  let lateChunk!: (chunk: string) => void;
  let signal!: AbortSignal;
  vi.mocked(chatApi.streamAnswer).mockImplementation((_question, _history, onChunk, abortSignal) => {
    lateChunk = onChunk;
    signal = abortSignal!;
    return new Promise<void>((resolve) => { finish = resolve; });
  });
  session.set("old-token");
  localStorage.setItem("real-estate-web-chat-history", JSON.stringify([
    { id: "old", role: "user", content: "Private previous conversation" },
  ]));
  render(<ChatWidget />);
  fireEvent.click(screen.getByRole("button", { name: "Mở trợ lý tư vấn bất động sản" }));
  const draft = screen.getByRole("textbox");
  fireEvent.change(draft, { target: { value: "Private question" } });
  fireEvent.click(screen.getByRole("button", { name: "Gửi câu hỏi" }));
  fireEvent.change(draft, { target: { value: "Unsent draft" } });
  act(() => session.clear());
  expect(signal.aborted).toBe(true);
  expect(screen.queryByRole("region")).toBeNull();
  await act(async () => { lateChunk("Late private response"); finish(); });
  expect(localStorage.getItem("real-estate-web-chat-history")).toBeNull();
  fireEvent.click(screen.getByRole("button", { name: "Mở trợ lý tư vấn bất động sản" }));
  expect((screen.getByRole("textbox") as HTMLTextAreaElement).value).toBe("");
  expect(screen.queryByText("Private previous conversation")).toBeNull();
  expect(screen.queryByText("Private question")).toBeNull();
  expect(screen.queryByText("Late private response")).toBeNull();
});

it("updates authentication and closes chatbot when another tab logs out", () => {
  function AuthState() { return <div>{useAuthenticated() ? "signed-in" : "signed-out"}</div>; }
  session.set("old-token");
  sessionStorage.setItem("real-estate-web-token", "old-token");
  sessionStorage.setItem("real-estate-web-chat-history", "private");
  sessionStorage.setItem("other-app", "keep");
  render(<><AuthState /><ChatWidget /></>);
  fireEvent.click(screen.getByRole("button", { name: "Mở trợ lý tư vấn bất động sản" }));
  localStorage.removeItem("real-estate-web-token");
  act(() => window.dispatchEvent(new StorageEvent("storage", {
    key: "real-estate-web-token", newValue: null, storageArea: localStorage,
  })));
  expect(screen.getByText("signed-out")).toBeTruthy();
  expect(screen.queryByRole("region")).toBeNull();
  expect(sessionStorage.getItem("real-estate-web-token")).toBeNull();
  expect(sessionStorage.getItem("real-estate-web-chat-history")).toBeNull();
  expect(sessionStorage.getItem("other-app")).toBe("keep");
});

it("does not restore favorites when an old request completes after logout", async () => {
  let finish!: (result: unknown) => void;
  vi.mocked(request).mockImplementationOnce(() => new Promise((resolve) => { finish = resolve; }));
  session.set("old-token");
  const pending = favoriteApi.list();
  session.clear();
  session.set("old-token");
  finish({ data: [{ id: 1 }] });
  await pending;
  expect(localStorage.getItem("real-estate-web-favorites")).toBeNull();
});

it("does not restore favorites from a delayed save across same-token login", async () => {
  let finish!: (result: unknown) => void;
  vi.mocked(request).mockImplementationOnce(() => new Promise((resolve) => { finish = resolve; }));
  session.set("same-token");
  const pending = favoriteApi.set(12, true);
  session.clear(); session.set("same-token");
  finish({ data: {} }); await pending;
  expect(localStorage.getItem("real-estate-web-favorites")).toBeNull();
});
