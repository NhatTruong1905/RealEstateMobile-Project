import { Bath, BedDouble, Building2, ChevronLeft, CircleAlert, CircleCheck, Clock3, Compass, FileText, Layers3, LoaderCircle, MapPin, MessageCircle, Pencil, Phone } from "lucide-react";
import { useParams } from "react-router-dom";
import { Link } from "../../components/ui/Navigation";
import { usePropertyDetail } from "../../hooks/usePropertyDetail";
import { PropertyGallery } from "../../components/property/PropertyGallery";
import { State } from "../../components/ui/State";
import { formatDate, formatMoney, statusLabel } from "../../utils/format";

export function PropertyDetailPage({ owned = false }: { owned?: boolean }) {
  const { id = "" } = useParams();
  const { property, error } = usePropertyDetail(id, owned);
  const backTo = owned ? "/seller/properties" : "/properties";
  if (error)
    return (
      <div className="container narrow page-space">
        <State
          icon={<Building2 />}
          title="Không thể mở tin này"
          text={error}
          action={
            <Link className="button button-secondary" to={backTo}>
              Về danh sách
            </Link>
          }
        />
      </div>
    );
  if (!property)
    return (
      <div className="detail-loading">
        <LoaderCircle className="spin" /> Đang tải thông tin...
      </div>
    );
  const transactionType = property.typeId === 2 ? "Cho thuê" : "Mua bán";
  const displayedType = owned
    ? property.typeName || (property.typeId ? transactionType : "Chưa cập nhật")
    : transactionType;
  const rejected = property.status === "Từ chối";
  const reviewTone = rejected ? "rejected" : property.status === "Chờ duyệt" ? "pending"
    : property.status === "Đang mở bán" ? "approved" : "neutral";
  const ReviewIcon = { rejected: CircleAlert, pending: Clock3, approved: CircleCheck, neutral: FileText }[reviewTone];
  return (
    <div className="page-shell detail-page">
      <div className="container">
        <Link className="back-link" to={backTo}>
          <ChevronLeft /> {owned ? "Tin đăng của tôi" : "Quay lại kết quả"}
        </Link>
        <PropertyGallery key={property.id} property={property} />
        <div className="detail-layout">
          <article>
            <div className="detail-kicker">
              <span>{displayedType}</span>
              <span>Mã tin #{property.id}</span>
            </div>
            <h1>{property.title}</h1>
            <p className="detail-location">
              <MapPin />
              {property.addressDetail ||
                property.address ||
                property.city ||
                "Địa chỉ đang cập nhật"}
            </p>
            <div className="detail-price">{owned && property.price != null
              ? new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 2 }).format(property.price)
              : formatMoney(property.price)}</div>
            <div className="detail-stats">
              <div>
                <Compass />
                <strong>{property.area ?? "—"} m²</strong>
                <span>Diện tích</span>
              </div>
              <div>
                <BedDouble />
                <strong>{property.bedroomCount ?? "—"}</strong>
                <span>Phòng ngủ</span>
              </div>
              <div>
                <Bath />
                <strong>{property.bathroomCount ?? "—"}</strong>
                <span>Phòng tắm</span>
              </div>
              <div>
                <Layers3 />
                <strong>{property.floorCount ?? "—"}</strong>
                <span>Số tầng</span>
              </div>
            </div>
            <section className="detail-section">
              <h2>Mô tả bất động sản</h2>
              <p>
                {property.description ||
                  "Chủ tin chưa cập nhật mô tả chi tiết."}
              </p>
            </section>
            <section className="detail-section">
              <h2>Thông tin bổ sung</h2>
              <dl className="facts">
                <div>
                  <dt>Hướng</dt>
                  <dd>{property.direction || "Chưa cập nhật"}</dd>
                </div>
                <div>
                  <dt>Pháp lý</dt>
                  <dd>{property.legal || "Chưa cập nhật"}</dd>
                </div>
                <div>
                  <dt>{owned ? "Phân khúc" : "Loại hình"}</dt>
                  <dd>
                    {property.categoryName ||
                      (!owned && property.typeName) ||
                      "Chưa cập nhật"}
                  </dd>
                </div>
                {owned && <div>
                  <dt>Địa chỉ đã nhập</dt>
                  <dd>{property.address || "Chưa cập nhật"}</dd>
                </div>}
                {owned && property.city && <div>
                  <dt>Tỉnh/thành phố</dt>
                  <dd>{property.city}</dd>
                </div>}
              </dl>
            </section>
          </article>
          {owned ? (
            <aside className="listing-review-card" aria-labelledby="listing-review-status">
              <header className="listing-review-header">
                <h2 id="listing-review-status">Trạng thái tin</h2>
                <span className={`listing-review-badge is-${reviewTone}`}>
                  <ReviewIcon size={16} aria-hidden="true" />
                  {statusLabel(property.status)}
                </span>
              </header>
              <dl className="listing-review-dates">
                <div><dt>Ngày đăng</dt><dd>{formatDate(property.createdDate)}</dd></div>
                {property.reviewedAt && <div><dt>Lần xét duyệt gần nhất</dt><dd>{formatDate(property.reviewedAt)}</dd></div>}
              </dl>
              {rejected && (
                <div className="listing-review-actions">
                  {property.rejectionReason && <section className="listing-review-reason">
                    <h3>Lý do từ chối</h3>
                    <p>{property.rejectionReason}</p>
                  </section>}
                  <Link className="button button-primary full" to={`/seller/properties/${property.id}/edit`}>
                    <Pencil size={16} aria-hidden="true" /> Sửa và gửi lại
                  </Link>
                </div>
              )}
            </aside>
          ) : <aside className="contact-card">
            <span className="eyebrow">Liên hệ chủ tin</span>
            <h3>{property.userFullname || "Chủ bất động sản"}</h3>
            <p>{property.userEmail || "Email chưa cập nhật"}</p>
            {property.userPhone ? (
              <a
                className="button button-accent full"
                href={`tel:${property.userPhone}`}
              >
                <Phone /> Gọi {property.userPhone}
              </a>
            ) : (
              <button className="button button-muted full" disabled>
                <Phone /> Chưa có số điện thoại
              </button>
            )}
            <Link className="button button-secondary full" to="/messages">
              <MessageCircle /> Mở tin nhắn
            </Link>
            <small>Hãy xác minh thông tin trước khi thực hiện giao dịch.</small>
          </aside>}
        </div>
      </div>
    </div>
  );
}

