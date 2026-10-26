import type { ApiEnvelope, UserProfile } from "../../../types";
import { request } from "../core/http";
import { session } from "../core/session";

export const accountApi = {
  async updateAvatar(file: File, profile: UserProfile): Promise<UserProfile> {
    const token = session.token;
    const generation = session.generation;
    const checkSession = () => {
      if (!token || session.token !== token || session.generation !== generation)
        throw new Error("Phiên đăng nhập đã thay đổi. Vui lòng tải lại hồ sơ.");
    };
    checkSession();
    const data = new FormData();
    data.append("file", file);
    data.append("username", profile.username);
    if (profile.phone) data.append("phone", profile.phone);
    await request<ApiEnvelope<unknown>>("/secure/update/profile", {
      method: "POST",
      body: data,
    });
    checkSession();
    const response = await request<ApiEnvelope<UserProfile>>("/secure/profile");
    checkSession();
    if (!response.data?.avatar || response.data.id !== profile.id || response.data.avatar === profile.avatar) {
      throw new Error("Chưa xác nhận được ảnh đại diện mới. Vui lòng tải lại hồ sơ trước khi thử lại.");
    }
    window.dispatchEvent(new Event("profile-change"));
    return response.data;
  },
  async getProfile(): Promise<UserProfile> {
    const response = await request<ApiEnvelope<UserProfile>>("/secure/profile");
    if (!response.data) throw new Error("Không tải được hồ sơ.");
    return response.data;
  },
};
