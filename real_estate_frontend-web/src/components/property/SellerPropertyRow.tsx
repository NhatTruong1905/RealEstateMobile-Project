import { fallbackPropertyImage } from "../../config/assets";
import type { Property } from "../../types";
import { formatMoney } from "../../utils/format";

export function SellerPropertyRow({ property }: { property: Property }) {
  return (
    <div className="seller-row">
      <img
        src={property.images?.[0] || property.image || fallbackPropertyImage}
        alt=""
      />
      <div>
        <h3>{property.title}</h3>
        <p>{property.address || property.city || "Chưa cập nhật địa chỉ"}</p>
      </div>
      <strong>{formatMoney(property.price)}</strong>
      <span className="status-pill">{property.status || "Chưa rõ"}</span>
    </div>
  );
}
