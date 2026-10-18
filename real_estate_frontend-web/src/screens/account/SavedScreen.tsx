import { useEffect, useState } from "react";
import { Bookmark, Heart } from "lucide-react";
import { Link } from "react-router-dom";
import { api } from "../../services/api/client";
import { PropertyCard } from "../../components/property/PropertyCard";
import { State } from "../../components/ui/State";
import { LoadingGrid } from "../properties/PropertiesScreen";
import type { Property } from "../../types";

export function SavedPage() {
  return (
    <DataPropertyPage
      title="Tin bạn đã lưu"
      eyebrow="Bộ sưu tập cá nhân"
      loader={api.favorites}
      empty="Bạn chưa lưu bất động sản nào."
    />
  );
}
function DataPropertyPage({
  title,
  eyebrow,
  loader,
  empty,
}: {
  title: string;
  eyebrow: string;
  loader: () => Promise<Property[]>;
  empty: string;
}) {
  const [items, setItems] = useState<Property[]>();
  const [error, setError] = useState("");
  useEffect(() => {
    loader()
      .then(setItems)
      .catch((e) => setError(e.message));
  }, [loader]);
  return (
    <div className="page-shell">
      <div className="container">
        <div className="page-intro compact-intro">
          <span className="eyebrow">{eyebrow}</span>
          <h1>{title}</h1>
        </div>
        {error ? (
          <State
            icon={<Bookmark />}
            title="Không thể tải dữ liệu"
            text={error}
          />
        ) : !items ? (
          <LoadingGrid />
        ) : items.length ? (
          <div className="property-grid">
            {items.map((p) => (
              <PropertyCard key={p.id} property={p} />
            ))}
          </div>
        ) : (
          <State
            icon={<Heart />}
            title={empty}
            text="Khi tìm thấy một nơi phù hợp, hãy lưu lại để xem sau."
            action={
              <Link className="button button-primary" to="/properties">
                Khám phá bất động sản
              </Link>
            }
          />
        )}
      </div>
    </div>
  );
}

