import { mockProfile } from "../../../data/mockProperties";
import type { ApiEnvelope, UserProfile } from "../../../types";
import { isMockMode, request } from "../core/http";

export const accountApi = {
  async getProfile(): Promise<UserProfile> {
    try {
      const response = await request<ApiEnvelope<UserProfile>>("/secure/profile");
      if (!response.data) throw new Error("Không tải được hồ sơ.");
      return response.data;
    } catch (error) {
      if (!isMockMode) throw error;
      return mockProfile;
    }
  },
};
