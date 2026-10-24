import { mockProperties } from "../../../data/mockProperties";
import type { ApiEnvelope, Property, PropertyPage } from "../../../types";
import { isMockMode, request } from "../core/http";
import { session } from "../core/session";

export const propertyApi = {
  async list(params: URLSearchParams): Promise<PropertyPage> {
    try {
      const response = await request<ApiEnvelope<PropertyPage>>(
        `/properties?${params.toString()}`,
      );
      if (!response.data) throw new Error("Phản hồi danh sách không hợp lệ.");
      return response.data;
    } catch (error) {
      if (!isMockMode) throw error;
      const title = params.get("title")?.toLocaleLowerCase("vi") || "";
      const address = params.get("address")?.toLocaleLowerCase("vi") || "";
      const typeId = Number(params.get("typeId") || 0);
      const page = Number(params.get("page") || 1);
      const limit = Number(params.get("limit") || 6);
      const filtered = mockProperties.filter(
        (property) =>
          property.status === "Đang mở bán" &&
          (!title || property.title.toLocaleLowerCase("vi").includes(title)) &&
          (!address ||
            property.address?.toLocaleLowerCase("vi").includes(address)) &&
          (!typeId || property.typeId === typeId),
      );
      return {
        content: filtered.slice((page - 1) * limit, page * limit),
        currentPage: page,
        totalItems: filtered.length,
        totalPages: Math.ceil(filtered.length / limit),
      };
    }
  },

  async getById(id: string): Promise<Property> {
    try {
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
    } catch (error) {
      if (!isMockMode) throw error;
      const property = mockProperties.find(
        (item) => item.id === Number(id) && item.status === "Đang mở bán",
      );
      if (!property) throw error;
      return property;
    }
  },
};
