import { useEffect, useState } from "react";
import { sellerApi } from "../../services/api/seller/sellerApi";
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
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(true);
  function reload() {
    setLoading(true);
    setError("");
    sellerApi
      .listMyProperties()
      .then(setItems)
      .catch((e: Error) => setError(e.message))
      .finally(() => setLoading(false));
  }
  useEffect(() => {
    let active = true;
    sellerApi
      .listMyProperties()
      .then((value) => {
        if (active) setItems(value);
      })
      .catch((e: Error) => {
        if (active) setError(e.message);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, []);
  if (loading) return <p role="status">Đang tải tin đăng...</p>;
  if (error)
    return (
      <div role="alert">
        {error}
        <button onClick={reload}>Tải lại</button>
      </div>
    );
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
