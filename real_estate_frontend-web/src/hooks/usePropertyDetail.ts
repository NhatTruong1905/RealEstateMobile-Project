import { useEffect, useState } from "react";
import { propertyApi } from "../services/api/property/propertyApi";
import type { Property } from "../types";

type Result = { id: string; property?: Property; error?: string };

export function usePropertyDetail(id: string) {
  const [result, setResult] = useState<Result>({ id });
  useEffect(() => {
    let cancelled = false;
    propertyApi.getById(id).then((property) => {
      if (!cancelled) setResult({ id, property });
    }).catch((error: unknown) => {
      if (!cancelled) setResult({ id, error: error instanceof Error ? error.message : "Không thể tải tin." });
    });
    return () => { cancelled = true; };
  }, [id]);
  // A response for the previous route must never supply the current gallery.
  return result.id === id ? result : { id };
}
