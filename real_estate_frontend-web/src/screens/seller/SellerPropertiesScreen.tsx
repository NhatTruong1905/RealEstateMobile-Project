import { useEffect, useState } from "react";
import { api } from "../../services/api/client";
import type { Property } from "../../types";
import { House } from "lucide-react";
import { Link } from "react-router-dom";
import { SellerPropertyRow } from "../../components/property/SellerPropertyRow";
import { State } from "../../components/ui/State";
export function SellerProperties() {
  return (
    <div>
      <div className="seller-header">
        <div>
          <span className="eyebrow">Quản lý nội dung</span>
          <h1>Tin đăng</h1>
        </div>
        <Link className="button button-primary" to="/seller/post">
          Đăng tin mới
        </Link>
      </div>
      <SellerPropertyList />
    </div>
  );
}
function SellerPropertyList() {
  const [items, setItems] = useState<Property[]>();
  useEffect(() => {
    api.myProperties().then(setItems);
  }, []);
  return items?.length ? (
    <div className="seller-list">
      {items.map((p) => (
        <SellerPropertyRow key={p.id} property={p} />
      ))}
    </div>
  ) : (
    <State
      icon={<House />}
      title="Chưa có tin nào"
      text="Tin do bạn đăng sẽ xuất hiện ở đây."
    />
  );
}
