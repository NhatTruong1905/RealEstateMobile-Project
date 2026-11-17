import { useEffect, useRef, useState } from "react";
import { Bath, BedDouble, Bookmark, Compass, LoaderCircle, MapPin } from "lucide-react";
import { useLocation } from "react-router-dom";
import { Link } from "../ui/Navigation";
import { useNavigate } from "../../hooks/useNavigate";
import { session } from "../../services/api/core/session";
import { favoriteApi, favoriteStore } from "../../services/api/favorite/favoriteApi";
import { getPropertyImages } from "../../services/images/propertyImages";
import { prefetchImage } from "../../services/images/imagePrefetch";
import { PropertyImage } from "./PropertyImage";
import type { Property } from "../../types";
import { formatMoney } from "../../utils/format";

export function PropertyCard({ property, priority = false }: { property: Property; priority?: boolean }) {
  const image = getPropertyImages(property)[0];
  const warmCover = () => prefetchImage(image);
  const navigate = useNavigate();
  const location = useLocation();
  const [saved, setSaved] = useState(() =>
    favoriteStore.get().includes(property.id),
  );
  const [saving, setSaving] = useState(false);
  const submitting = useRef(false);
  const [saveError, setSaveError] = useState("");

  useEffect(() => {
    const sync = () => setSaved(favoriteStore.get().includes(property.id));
    addEventListener("favorites-change", sync);
    return () => removeEventListener("favorites-change", sync);
  }, [property.id]);

  async function toggleSaved() {
    if (submitting.current) return;
    if (!session.token) {
      navigate(
        `/login?returnTo=${encodeURIComponent(location.pathname + location.search)}&saveProperty=${property.id}`,
      );
      return;
    }

    const next = !saved;
    submitting.current = true;
    setSaveError("");
    setSaving(true);
    try {
      await favoriteApi.set(property.id, next);
      setSaved(next);
    } catch (error) {
      setSaveError(error instanceof Error ? error.message : "Không thể lưu tin. Vui lòng thử lại.");
    } finally {
      submitting.current = false;
      setSaving(false);
    }
  }

  return (
    <article className="property-card" onPointerEnter={warmCover} onFocus={warmCover} onTouchStart={warmCover}>
      <Link className="property-image" to={`/properties/${property.id}`}>
        <PropertyImage
          src={image}
          alt=""
          loading={priority ? "eager" : "lazy"}
          decoding="async"
        />
        <span className="property-type">
          {property.typeId === 2 ? "Cho thuê" : "Mua bán"}
        </span>
      </Link>
      <button
        className={saved ? "save-property saved" : "save-property"}
        type="button"
        onClick={toggleSaved}
        disabled={saving}
        aria-busy={saving}
        aria-pressed={saved}
        aria-label={saved ? "Bỏ lưu bất động sản" : "Lưu bất động sản"}
        title={saved ? "Bỏ lưu" : "Lưu tin"}
      >
        {saving ? <LoaderCircle className="spin" aria-hidden="true" /> : <Bookmark fill={saved ? "currentColor" : "none"} />}
      </button>
      <div className="property-body">
        {saveError && <p className="form-error" role="alert">{saveError}</p>}
        <div className="property-price">{formatMoney(property.price)}</div>
        <h3>
          <Link to={`/properties/${property.id}`}>
            {property.title || "Bất động sản chưa đặt tên"}
          </Link>
        </h3>
        <p className="location">
          <MapPin />
          {property.addressDetail ||
            property.address ||
            property.city ||
            "Địa chỉ đang cập nhật"}
        </p>
        <div className="property-meta">
          <span>
            <BedDouble />
            {property.bedroomCount ?? "—"} PN
          </span>
          <span>
            <Bath />
            {property.bathroomCount ?? "—"} PT
          </span>
          <span>
            <Compass />
            {property.area ? `${property.area} m²` : "—"}
          </span>
        </div>
      </div>
    </article>
  );
}
