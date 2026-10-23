import { mockProperties } from "../../../data/mockProperties";
import type { ApiEnvelope, Property } from "../../../types";
import { isMockMode, request } from "../core/http";

export interface PropertyOption {
  id: number;
  name: string;
  districtName?: string;
}
export interface PropertyOptions {
  types: PropertyOption[];
  categories: PropertyOption[];
  wards: PropertyOption[];
}

export const sellerApi = {
  async options(): Promise<PropertyOptions> {
    const response = await request<ApiEnvelope<PropertyOptions>>(
      "/secure/property-options",
    );
    if (!response.data) throw new Error("Không tải được danh mục.");
    return response.data;
  },
  async create(data: FormData): Promise<Property> {
    const response = await request<ApiEnvelope<Property>>(
      "/secure/properties",
      { method: "POST", body: data },
    );
    if (!response.data?.id || !response.data.status)
      throw new Error(
        "Máy chủ chưa xác nhận tin đăng. Hãy kiểm tra Tin đăng trước khi thử lại.",
      );
    return response.data;
  },
  async listMyProperties(): Promise<Property[]> {
    try {
      const response =
        await request<ApiEnvelope<Property[]>>("/secure/properties");
      return response.data || [];
    } catch (error) {
      if (!isMockMode) throw error;
      return mockProperties.slice(0, 7);
    }
  },
};
