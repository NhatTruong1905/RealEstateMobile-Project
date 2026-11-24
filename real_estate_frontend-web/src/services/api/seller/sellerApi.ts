import type { ApiEnvelope, Property, PropertyPage } from "../../../types";
import { request } from "../core/http";
import { session } from "../core/session";

const pendingPages = new Map<string, Promise<PropertyPage>>();

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
  async get(id: number): Promise<Property> {
    const response = await request<ApiEnvelope<Property>>(`/secure/properties/${id}/mine`);
    if (!response.data) throw new Error("Không tải được tin đăng.");
    return response.data;
  },
  async saveRejectedDraft(id: number, data: FormData): Promise<Property> {
    data.set("id", String(id));
    const response = await request<ApiEnvelope<Property>>("/secure/properties?rejectedDraft=true", {
      method: "POST", body: data,
    });
    if (!response.data?.id) throw new Error("Máy chủ chưa xác nhận lưu tin.");
    return response.data;
  },
  async resubmit(id: number): Promise<Property> {
    const response = await request<ApiEnvelope<Property>>(`/secure/properties/${id}/resubmit`, { method: "POST" });
    if (!response.data?.id) throw new Error("Máy chủ chưa xác nhận gửi lại tin.");
    return response.data;
  },
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
    const response =
      await request<ApiEnvelope<Property[]>>("/secure/properties");
    return response.data || [];
  },
  listMyPropertiesPage(page = 1, limit = 6): Promise<PropertyPage> {
    const key = `${session.generation}:${page}:${limit}`;
    const pending = pendingPages.get(key);
    if (pending) return pending;
    const result = request<ApiEnvelope<PropertyPage>>(`/secure/properties?page=${page}&limit=${limit}`)
      .then((response) => {
        if (!response.data || !Array.isArray(response.data.content)) throw new Error("Phản hồi danh sách tin không hợp lệ.");
        return response.data;
      })
      .finally(() => pendingPages.delete(key));
    pendingPages.set(key, result);
    return result;
  },
};
