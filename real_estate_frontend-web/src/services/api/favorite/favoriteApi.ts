import { mockProperties } from "../../../data/mockProperties";
import type { ApiEnvelope, Property } from "../../../types";
import { isMockMode, request } from "../core/http";

const FAVORITES_KEY = "real-estate-web-favorites";

export const favoriteStore = {
  get(): number[] {
    try {
      return JSON.parse(localStorage.getItem(FAVORITES_KEY) || "[]") as number[];
    } catch {
      return [];
    }
  },
  set(ids: number[]) {
    localStorage.setItem(FAVORITES_KEY, JSON.stringify(ids));
    window.dispatchEvent(new Event("favorites-change"));
  },
};

export const favoriteApi = {
  async list(): Promise<Property[]> {
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

  async set(propertyId: number, saved: boolean): Promise<number[]> {
    const ids = new Set(favoriteStore.get());
    if (saved) ids.add(propertyId);
    else ids.delete(propertyId);
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
};
