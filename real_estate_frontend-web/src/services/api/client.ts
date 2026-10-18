import type { ApiEnvelope, Property, PropertyPage, UserProfile } from "../../types";
import { mockProfile, mockProperties } from "../../data/mockProperties";

const API_BASE = (
  import.meta.env.VITE_API_BASE_URL || "http://localhost:8080/api"
).replace(/\/$/, "");
const TOKEN_KEY = "real-estate-web-token";
const FAVORITES_KEY = "real-estate-web-favorites";
export const isMockMode = import.meta.env.VITE_USE_MOCKS !== "false";

export const favoriteStore = {
  get(): number[] {
    try { return JSON.parse(localStorage.getItem(FAVORITES_KEY) || "[]") as number[]; }
    catch { return []; }
  },
  set(ids: number[]) {
    localStorage.setItem(FAVORITES_KEY, JSON.stringify(ids));
    window.dispatchEvent(new Event("favorites-change"));
  },
};

export const session = {
  get token() {
    return localStorage.getItem(TOKEN_KEY);
  },
  set(token: string) {
    localStorage.setItem(TOKEN_KEY, token);
    window.dispatchEvent(new Event("session-change"));
  },
  clear() {
    localStorage.removeItem(TOKEN_KEY);
    window.dispatchEvent(new Event("session-change"));
  },
};

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers = new Headers(init.headers);
  if (!(init.body instanceof FormData))
    headers.set("Content-Type", "application/json");
  if (session.token) headers.set("Authorization", `Bearer ${session.token}`);
  const response = await fetch(`${API_BASE}${path}`, { ...init, headers });
  const body = await response.json().catch(() => null);
  if (!response.ok) {
    const message =
      typeof body === "string"
        ? body
        : body?.message || "Không thể hoàn tất yêu cầu.";
    throw new Error(message);
  }
  return body as T;
}

export const api = {
  async properties(params: URLSearchParams) {
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
        (p) =>
          (!title || p.title.toLocaleLowerCase("vi").includes(title)) &&
          (!address || p.address?.toLocaleLowerCase("vi").includes(address)) &&
          (!typeId || p.typeId === typeId),
      );
      return {
        content: filtered.slice((page - 1) * limit, page * limit),
        currentPage: page,
        totalItems: filtered.length,
        totalPages: Math.ceil(filtered.length / limit),
      };
    }
  },
  async property(id: string) {
    try {
      if (session.token) {
        const response = await request<ApiEnvelope<Property>>(`/secure/properties/${id}`);
        if (response.data) return response.data;
      }
      const response = await request<ApiEnvelope<PropertyPage>>('/properties?page=1&limit=200');
      const property = response.data?.content.find((item) => item.id === Number(id));
      if (!property) throw new Error("Không tìm thấy bất động sản.");
      return property;
    } catch (error) {
      if (!isMockMode) throw error;
      const property = mockProperties.find((p) => p.id === Number(id));
      if (!property) throw error;
      return property;
    }
  },
  async login(username: string, password: string) {
    try {
      const response = await request<{ token: string }>("/auth/login", {
        method: "POST",
        body: JSON.stringify({ username, password }),
      });
      session.set(response.token);
      return response;
    } catch (error) {
      if (!isMockMode) throw error;
      const response = { token: `mock-session-${username || password.length}` };
      session.set(response.token);
      return response;
    }
  },
  async register(data: Record<string, string>) {
    try {
      return await request<ApiEnvelope<never>>("/auth/register", {
        method: "POST",
        body: JSON.stringify(data),
      });
    } catch (error) {
      if (!isMockMode) throw error;
      return { message: "Tạo tài khoản trải nghiệm thành công" };
    }
  },
  async profile() {
    try {
      const response =
        await request<ApiEnvelope<UserProfile>>("/secure/profile");
      if (!response.data) throw new Error("Không tải được hồ sơ.");
      return response.data;
    } catch (error) {
      if (!isMockMode) throw error;
      return mockProfile;
    }
  },
  async favorites() {
    try {
      const response = await request<ApiEnvelope<Property[]>>(
        "/secure/favorite-properties",
      );
      const properties = response.data || [];
      favoriteStore.set(properties.map((property) => property.id));
      return properties;
    } catch (error) {
      if (!isMockMode) throw error;
      const ids = new Set(favoriteStore.get());
      return mockProperties.filter((property) => ids.has(property.id));
    }
  },
  async setFavorite(propertyId: number, saved: boolean) {
    const ids = new Set(favoriteStore.get());
    if (saved) ids.add(propertyId); else ids.delete(propertyId);
    const propertyIds = [...ids];
    try {
      await request<ApiEnvelope<unknown>>("/secure/favorite-properties", {
        method: "POST",
        body: JSON.stringify({ propertyIds }),
      });
    } catch (error) {
      if (!isMockMode) throw error;
    }
    favoriteStore.set(propertyIds);
    return propertyIds;
  },
  async myProperties() {
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
