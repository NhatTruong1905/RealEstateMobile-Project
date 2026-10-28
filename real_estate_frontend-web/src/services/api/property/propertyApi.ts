import type { ApiEnvelope, Property, PropertyPage } from "../../../types";
import { request } from "../core/http";
import { session } from "../core/session";

export const propertyApi = {
  async list(params: URLSearchParams): Promise<PropertyPage> {
    const response = await request<ApiEnvelope<PropertyPage>>(
      `/properties?${params.toString()}`,
    );
    if (!response.data) throw new Error("Phản hồi danh sách không hợp lệ.");
    return response.data;
  },

  async getById(id: string): Promise<Property> {
    if (session.token) {
      const response = await request<ApiEnvelope<Property>>(
        `/secure/properties/${id}`,
      );
      if (response.data) return response.data;
    }
    const response = await request<ApiEnvelope<PropertyPage>>(
      "/properties?page=1&limit=200",
    );
    const property = response.data?.content.find(
      (item) => item.id === Number(id),
    );
    if (!property) throw new Error("Không tìm thấy bất động sản.");
    return property;
  },
};
