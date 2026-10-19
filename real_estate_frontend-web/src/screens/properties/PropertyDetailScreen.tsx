import { useEffect, useState } from "react";
import { Bath, BedDouble, Building2, ChevronLeft, Compass, House, Layers3, LoaderCircle, MapPin, MessageCircle, Phone } from "lucide-react";
import { Link, useParams } from "react-router-dom";
import { propertyApi } from "../../services/api/property/propertyApi";
import { fallbackPropertyImage } from "../../config/assets";
import { State } from "../../components/ui/State";
import type { Property } from "../../types";
import { formatMoney } from "../../utils/format";

export function PropertyDetailPage() {
  const { id = "" } = useParams();
  const [property, setProperty] = useState<Property>();
  const [error, setError] = useState("");
  useEffect(() => {
    propertyApi
      .getById(id)
      .then(setProperty)
      .catch((e) => setError(e.message));
  }, [id]);
  if (error)
    return (
      <div className="container narrow page-space">
        <State
          icon={<Building2 />}
          title="Không thể mở tin này"
          text={error}
          action={
            <Link className="button button-secondary" to="/properties">
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
  const images = property.images?.length
    ? property.images
    : [property.image || fallbackPropertyImage];
  return (
    <div className="page-shell detail-page">
      <div className="container">
        <Link className="back-link" to="/properties">
          <ChevronLeft /> Quay lại kết quả
        </Link>
        <div className="gallery">
          <img className="gallery-main" src={images[0]} alt="" />
          <div className="gallery-stack">
            {images.slice(1, 3).map((src, i) => (
              <img key={i} src={src} alt="" />
            ))}
            {images.length < 2 && (
              <div className="gallery-placeholder">
                <House />
              </div>
            )}
          </div>
        </div>
        <div className="detail-layout">
          <article>
            <div className="detail-kicker">
              <span>{property.typeId === 2 ? "Cho thuê" : "Mua bán"}</span>
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
            <div className="detail-price">{formatMoney(property.price)}</div>
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
                  <dt>Loại hình</dt>
                  <dd>
                    {property.categoryName ||
                      property.typeName ||
                      "Chưa cập nhật"}
                  </dd>
                </div>
              </dl>
            </section>
          </article>
          <aside className="contact-card">
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
          </aside>
        </div>
      </div>
    </div>
  );
}

