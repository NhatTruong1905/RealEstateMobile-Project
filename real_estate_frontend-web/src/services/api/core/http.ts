import { session } from "./session";

const API_BASE = "http://localhost:8080/api";

export const isMockMode = import.meta.env.VITE_USE_MOCKS === "true";

export async function request<T>(
  path: string,
  init: RequestInit = {},
): Promise<T> {
  const headers = new Headers(init.headers);
  if (!(init.body instanceof FormData)) {
    headers.set("Content-Type", "application/json");
  }
  if (session.token) headers.set("Authorization", `Bearer ${session.token}`);

  const response = await fetch(`${API_BASE}${path}`, { ...init, headers });
  const responseText = await response.text();
  let body: unknown = null;

  if (responseText) {
    try {
      body = JSON.parse(responseText);
    } catch {
      body = responseText;
    }
  }

  if (!response.ok) {
    let message = "Không thể hoàn tất yêu cầu.";
    if (typeof body === "string") {
      message = body;
    } else if (body && typeof body === "object") {
      const errorBody = body as Record<string, unknown>;
      if (typeof errorBody.message === "string") {
        message = errorBody.message;
      } else {
        const validationErrors = Object.values(errorBody).filter(
          (value): value is string => typeof value === "string",
        );
        if (validationErrors.length) message = validationErrors.join("\n");
      }
    }
    throw new Error(message);
  }

  return body as T;
}
