import { mockProperties } from "../../../data/mockProperties";
import type { ApiEnvelope, Property } from "../../../types";
import { isMockMode, request } from "../core/http";

export const sellerApi = {
  async listMyProperties(): Promise<Property[]> {
    try {
      const response = await request<ApiEnvelope<Property[]>>(
        "/secure/properties",
      );
      return response.data || [];
    } catch (error) {
      if (!isMockMode) throw error;
      return mockProperties.slice(0, 7);
    }
  },
};
