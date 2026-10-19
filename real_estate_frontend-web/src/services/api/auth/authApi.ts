import { request } from "../core/http";
import { session } from "../core/session";

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
      body: JSON.stringify({ username, password }),
    });
    if (!response.token) throw new Error("Máy chủ không trả về token đăng nhập.");
    session.set(response.token);
    return response;
  },

  register(data: RegisterRequest) {
    return request<{ message: string }>("/auth/register", {
      method: "POST",
      body: JSON.stringify(data),
    });
  },
};
