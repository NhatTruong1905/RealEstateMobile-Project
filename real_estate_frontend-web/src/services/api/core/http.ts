import { session } from "./session";

const API_BASE = (import.meta.env.VITE_API_BASE_URL || "http://localhost:8080/api").replace(/\/+$/, "");

export const isMockMode = import.meta.env.VITE_USE_MOCKS === "true";

export class ApiError extends Error {
  status: number;
  fields: Record<string, string>;
  constructor(
    status: number,
    message: string,
    fields: Record<string, string> = {},
  ) {
    super(message);
    this.status = status;
    this.fields = fields;
  }
}
export async function request<T>(
  path: string,
  init: RequestInit = {},
): Promise<T> {
  const headers = new Headers(init.headers);
  if (!(init.body instanceof FormData)) {
    headers.set("Content-Type", "application/json");
  }
  if (session.token) headers.set("Authorization", `Bearer ${session.token}`);

  let response: Response;
  try {
    response = await fetch(`${API_BASE}${path}`, { ...init, headers });
  } catch {
    throw new ApiError(
      0,
      init.method === "POST"
        ? "Lỗi kết nối. Hãy kiểm tra Tin đăng trước khi thử lại để tránh tạo trùng."
        : "Không thể kết nối máy chủ. Vui lòng thử tải lại.",
    );
  }
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
    const errorBody =
      body && typeof body === "object" ? (body as Record<string, unknown>) : {};
    const detail =
      errorBody.data && typeof errorBody.data === "object"
        ? errorBody.data
        : errorBody;
    const fields = Object.fromEntries(
      Object.entries(detail).filter(
        (entry): entry is [string, string] => typeof entry[1] === "string",
      ),
    );
    const hints: Record<number, string> = {
      401: "Vui lòng đăng nhập lại.",
      403: "Bạn không có quyền thực hiện thao tác này.",
      404: "Không tìm thấy tin đăng.",
      409: "Tin đã thay đổi. Vui lòng tải lại trước khi thao tác.",
    };
    throw new ApiError(
      response.status,
      hints[response.status] || message,
      fields,
    );
  }

  return body as T;
}
