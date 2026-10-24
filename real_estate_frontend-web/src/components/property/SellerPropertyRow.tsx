import { fallbackPropertyImage } from "../../config/assets";
import type { Property } from "../../types";
import { formatMoney, formatDate, statusLabel } from "../../utils/format";

export function SellerPropertyRow({ property }: { property: Property }) {
  return (
    <div className="seller-row">
      <img
        src={property.images?.[0] || property.image || fallbackPropertyImage}
        alt=""
      />
      <div>
        <h3>{property.title}</h3>
        <small>{formatDate(property.createdDate)}</small>
        {property.status === "Từ chối" && property.rejectionReason && (
          <p>Lý do từ chối: {property.rejectionReason}</p>
        )}
        <p>{property.address || property.city || "Chưa cập nhật địa chỉ"}</p>
      </div>
      <strong>{formatMoney(property.price)}</strong>
      <span className="status-pill">{statusLabel(property.status)}</span>
    </div>
  );
}
