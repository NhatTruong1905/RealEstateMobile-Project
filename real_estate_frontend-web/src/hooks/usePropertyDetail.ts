import { useEffect, useState } from "react";
import { propertyApi } from "../services/api/property/propertyApi";
import { sellerApi } from "../services/api/seller/sellerApi";
import type { Property } from "../types";

type Result = { id: string; owned?: boolean; property?: Property; error?: string };

export function usePropertyDetail(id: string, owned = false) {
  const [result, setResult] = useState<Result>({ id });
  useEffect(() => {
    let cancelled = false;
    const load = owned ? sellerApi.get(Number(id)) : propertyApi.getById(id);
    load.then((property) => {
      if (!cancelled) setResult({ id, owned, property });
    }).catch((error: unknown) => {
      if (!cancelled) setResult({ id, owned, error: error instanceof Error ? error.message : "Không thể tải tin." });
    });
    return () => { cancelled = true; };
  }, [id, owned]);
  // A response for the previous route must never supply the current gallery.
  return result.id === id && result.owned === owned ? result : { id };
}
