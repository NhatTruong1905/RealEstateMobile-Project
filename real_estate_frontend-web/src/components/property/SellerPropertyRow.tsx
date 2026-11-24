import { fallbackPropertyImage } from "../../config/assets";
import type { Property } from "../../types";
import { formatMoney, formatDate, statusLabel } from "../../utils/format";
import { Link } from "../ui/Navigation";

export function SellerPropertyRow({ property }: { property: Property }) {
  return (
    <div className="seller-row">
      <img
        src={property.images?.[0] || property.image || fallbackPropertyImage}
        alt=""
      />
      <div>
        <h3><Link className="seller-row-details" to={`/seller/properties/${property.id}`}>{property.title}</Link></h3>
        <small>{formatDate(property.createdDate)}</small>
        {property.status === "Từ chối" && property.rejectionReason && (
          <p>Lý do từ chối: {property.rejectionReason}</p>
        )}
        <p>{property.address || property.city || "Chưa cập nhật địa chỉ"}</p>
        {property.status === "Từ chối" && (
          <Link className="text-link seller-row-edit" to={`/seller/properties/${property.id}/edit`}>Sửa và gửi lại</Link>
        )}
      </div>
      <strong>{formatMoney(property.price)}</strong>
      <span className="status-pill">{statusLabel(property.status)}</span>
    </div>
  );
}
