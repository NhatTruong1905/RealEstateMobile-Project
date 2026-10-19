import { useEffect, useState } from "react";
import { Bath, BedDouble, Bookmark, Compass, MapPin } from "lucide-react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { session } from "../../services/api/core/session";
import { favoriteApi, favoriteStore } from "../../services/api/favorite/favoriteApi";
import { fallbackPropertyImage } from "../../config/assets";
import type { Property } from "../../types";
import { formatMoney } from "../../utils/format";

export function PropertyCard({ property }: { property: Property }) {
  const image = property.images?.[0] || property.image || fallbackPropertyImage;
  const navigate = useNavigate();
  const location = useLocation();
  const [saved, setSaved] = useState(() =>
    favoriteStore.get().includes(property.id),
  );
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const sync = () => setSaved(favoriteStore.get().includes(property.id));
    addEventListener("favorites-change", sync);
    return () => removeEventListener("favorites-change", sync);
  }, [property.id]);

  async function toggleSaved() {
    if (!session.token) {
      navigate(
        `/login?returnTo=${encodeURIComponent(location.pathname + location.search)}&saveProperty=${property.id}`,
      );
      return;
    }

    const next = !saved;
    setSaving(true);
    try {
      await favoriteApi.set(property.id, next);
      setSaved(next);
    } finally {
      setSaving(false);
    }
  }

  return (
    <article className="property-card">
      <Link className="property-image" to={`/properties/${property.id}`}>
        <img
          src={image}
          onError={(event) => {
            event.currentTarget.src = fallbackPropertyImage;
          }}
          alt=""
          loading="lazy"
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
        aria-pressed={saved}
        aria-label={saved ? "Bỏ lưu bất động sản" : "Lưu bất động sản"}
        title={saved ? "Bỏ lưu" : "Lưu tin"}
      >
        <Bookmark fill={saved ? "currentColor" : "none"} />
      </button>
      <div className="property-body">
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
