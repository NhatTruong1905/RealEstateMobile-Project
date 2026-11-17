import { fallbackPropertyImage } from "../../config/assets";
import type { Property } from "../../types";

export function getPropertyImages(property: Property): string[] {
  const images = property.images?.filter((url) => Boolean(url?.trim()));
  return images?.length ? images : [property.image || fallbackPropertyImage];
}
