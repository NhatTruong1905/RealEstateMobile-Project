import { useEffect, useState } from "react";
import { api } from "../../services/api/client";
import type { Property } from "../../types";
import { ArrowRight, House, Sparkles } from "lucide-react";
import { Link } from "react-router-dom";
import { SellerPropertyRow } from "../../components/property/SellerPropertyRow";
import { State } from "../../components/ui/State";

export function SellerOverview() {
  const [items, setItems] = useState<Property[]>();
  useEffect(() => {
    api.myProperties().then(setItems);
  }, []);
  const published = items?.filter((i) => i.status === "PUBLISHED").length;
  return (
    <>
      <div className="seller-header">
        <div>
          <span className="eyebrow">Khu vực người bán</span>
          <h1>Tổng quan</h1>
        </div>
        <Link className="button button-primary" to="/seller/post">
          Đăng tin mới <ArrowRight />
        </Link>
      </div>
      <div className="metric-grid">
        <article>
          <span>Tổng số tin</span>
          <strong>{items?.length ?? "—"}</strong>
          <small>Dữ liệu từ tài khoản của bạn</small>
        </article>
        <article>
          <span>Đang hiển thị</span>
          <strong>{published ?? "—"}</strong>
          <small>Tin có trạng thái xuất bản</small>
        </article>
        <article className="metric-note">
          <Sparkles />
          <span>Hiệu quả tin đăng</span>
          <p>
            Số lượt xem chưa được backend cung cấp nên không hiển thị dữ liệu
            ước đoán.
          </p>
        </article>
      </div>
      <section className="seller-section">
        <h2>Tin gần đây</h2>
        {items?.length ? (
          <div className="seller-list">
            {items.slice(0, 4).map((p) => (
              <SellerPropertyRow key={p.id} property={p} />
            ))}
          </div>
        ) : (
          <State
            icon={<House />}
            title="Chưa có tin đăng"
            text="Tạo tin đầu tiên để bắt đầu tiếp cận người mua."
            action={
              <Link className="button button-primary" to="/seller/post">
                Đăng tin
              </Link>
            }
          />
        )}
      </section>
    </>
  );
}
