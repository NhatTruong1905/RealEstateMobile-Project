import { request } from "../core/http";
import { session } from "../core/session";
import { normalizeAuthField } from "./normalizeAuth";

export interface RegisterRequest {
  fullname: string;
  username: string;
  password: string;
  email: string;
  phone: string;
}

export const authApi = {
  async login(username: string, password: string) {
    const response = await request<{ token: string }>("/auth/login", {
      method: "POST",
      body: JSON.stringify({ username: normalizeAuthField("username", username), password }),
    });
    if (!response.token) throw new Error("Máy chủ không trả về token đăng nhập.");
    session.set(response.token);
    return response;
  },

  register(data: RegisterRequest) {
    return request<{ message: string }>("/auth/register", {
      method: "POST",
      body: JSON.stringify(Object.fromEntries(
        Object.entries(data).map(([name, value]) => [name, normalizeAuthField(name, value)]),
      )),
    });
  },
};
