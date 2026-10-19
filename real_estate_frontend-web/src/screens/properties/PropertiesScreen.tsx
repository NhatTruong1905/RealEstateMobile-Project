import { useEffect, useState } from "react";
import { Building2, ChevronLeft, ChevronRight, List, Map as MapIcon, Search, SlidersHorizontal, X } from "lucide-react";
import { Link, useSearchParams } from "react-router-dom";
import { propertyApi } from "../../services/api/property/propertyApi";
import { PropertyCard } from "../../components/property/PropertyCard";
import { PropertyMap } from "../../components/property/PropertyMap";
import { State } from "../../components/ui/State";
import type { PropertyPage } from "../../types";

function FilterPanel({
  params,
  update,
  close,
}: {
  params: URLSearchParams;
  update: (key: string, value: string) => void;
  close?: () => void;
}) {
  return (
    <aside className="filters">
      <div className="filter-title">
        <div>
          <SlidersHorizontal /> Bộ lọc
        </div>
        {close && (
          <button
            className="icon-button"
            onClick={close}
            aria-label="Đóng bộ lọc"
          >
            <X />
          </button>
        )}
      </div>
      <label>
        Từ khóa
        <input
          value={params.get("title") || ""}
          onChange={(e) => update("title", e.target.value)}
          placeholder="Tên hoặc mô tả"
        />
      </label>
      <label>
        Khu vực
        <input
          value={params.get("address") || ""}
          onChange={(e) => update("address", e.target.value)}
          placeholder="Quận, đường, thành phố"
        />
      </label>
      <label>
        Nhu cầu
        <select
          value={params.get("typeId") || ""}
          onChange={(e) => update("typeId", e.target.value)}
        >
          <option value="">Tất cả</option>
          <option value="1">Mua bán</option>
          <option value="2">Cho thuê</option>
        </select>
      </label>
      <div className="filter-row">
        <label>
          Giá từ
          <input
            type="number"
            value={params.get("fromPrice") || ""}
            onChange={(e) => update("fromPrice", e.target.value)}
            placeholder="0"
          />
        </label>
        <label>
          Đến
          <input
            type="number"
            value={params.get("toPrice") || ""}
            onChange={(e) => update("toPrice", e.target.value)}
            placeholder="Bất kỳ"
          />
        </label>
      </div>
      <label>
        Phòng ngủ
        <select
          value={params.get("bedroomCount") || ""}
          onChange={(e) => update("bedroomCount", e.target.value)}
        >
          <option value="">Bất kỳ</option>
          {[1, 2, 3, 4, 5].map((n) => (
            <option key={n}>{n}</option>
          ))}
        </select>
      </label>
      <button
        className="button button-secondary full"
        onClick={() => {
          window.history.pushState({}, "", "/properties");
          location.reload();
        }}
      >
        Xóa bộ lọc
      </button>
    </aside>
  );
}

export function PropertiesPage() {
  const [params, setParams] = useSearchParams();
  const [result, setResult] = useState<PropertyPage>();
  const [status, setStatus] = useState<"loading" | "ready" | "error">(
    "loading",
  );
  const [filters, setFilters] = useState(false);
  const [mapView, setMapView] = useState(false);
  const [selectedProperty, setSelectedProperty] = useState<number>();
  const query = params.toString();
  useEffect(() => {
    const q = new URLSearchParams(query);
    if (!q.has("page")) q.set("page", "1");
    if (!q.has("limit")) q.set("limit", "6");
    propertyApi
      .list(q)
      .then((r) => {
        setResult(r);
        setStatus("ready");
      })
      .catch(() => setStatus("error"));
  }, [query]);
  function update(key: string, value: string) {
    setStatus("loading");
    const next = new URLSearchParams(params);
    if (value) next.set(key, value);
    else next.delete(key);
    next.set("page", "1");
    setParams(next, { replace: true });
  }
  return (
    <div className="page-shell">
      <div className="container">
        <div className="page-intro">
          <span className="eyebrow">Kho bất động sản</span>
          <h1>
            Tìm nơi phù hợp
            <br />
            với kế hoạch của bạn.
          </h1>
          <p>Bộ lọc của bạn được lưu lại trên đường dẫn này.</p>
        </div>
        <button
          className="button button-secondary mobile-filter"
          onClick={() => setFilters(true)}
        >
          <SlidersHorizontal /> Lọc kết quả
        </button>
        <div className={mapView ? "listing-layout with-map" : "listing-layout"}>
          <div
            className={filters ? "filter-drawer open" : "filter-drawer"}
            onClick={(e) => {
              if (e.currentTarget === e.target) setFilters(false);
            }}
          >
            <FilterPanel
              params={params}
              update={update}
              close={() => setFilters(false)}
            />
          </div>
          <section className="results">
            <div className="results-toolbar">
              <p>
                {status === "ready" ? (
                  <>
                    <strong>{result?.totalItems ?? 0}</strong> bất động sản phù
                    hợp
                  </>
                ) : (
                  "Đang tìm bất động sản..."
                )}
              </p>
              <div className="results-actions">
                {mapView && (
                  <button
                    className="button button-secondary map-filter-button"
                    type="button"
                    onClick={() => setFilters(true)}
                  >
                    <SlidersHorizontal /> Bộ lọc
                  </button>
                )}
                <select aria-label="Sắp xếp">
                  <option>Mới nhất</option>
                </select>
                <button
                  className={mapView ? "button button-primary" : "button button-secondary"}
                  type="button"
                  onClick={() => setMapView((current) => !current)}
                  aria-pressed={mapView}
                >
                  {mapView ? <List /> : <MapIcon />}
                  {mapView ? "Xem danh sách" : "Xem bản đồ"}
                </button>
              </div>
            </div>
            {status === "loading" && <LoadingGrid />}
            {status === "error" && (
              <State
                icon={<Building2 />}
                title="Chưa thể tải danh sách"
                text="Kiểm tra kết nối backend rồi thử lại."
                action={
                  <button
                    className="button button-secondary"
                    onClick={() => location.reload()}
                  >
                    Thử lại
                  </button>
                }
              />
            )}{" "}
            {status === "ready" && !result?.content.length && (
              <State
                icon={<Search />}
                title="Chưa tìm thấy lựa chọn phù hợp"
                text="Hãy nới rộng khu vực hoặc khoảng giá để xem thêm kết quả."
                action={
                  <Link className="button button-secondary" to="/properties">
                    Xóa bộ lọc
                  </Link>
                }
              />
            )}{" "}
            {status === "ready" && Boolean(result?.content.length) && (
              <>
                {mapView ? (
                  <div className="map-results-split">
                    <div className="map-property-list">
                      {result!.content.map((property) => (
                        <div
                          id={`map-property-${property.id}`}
                          className={selectedProperty === property.id ? "map-property-item selected" : "map-property-item"}
                          onMouseEnter={() => setSelectedProperty(property.id)}
                          key={property.id}
                        >
                          <PropertyCard property={property} />
                        </div>
                      ))}
                    </div>
                    <PropertyMap
                      properties={result!.content}
                      selectedId={selectedProperty}
                      onSelect={(id) => {
                        setSelectedProperty(id);
                        window.setTimeout(() => {
                          document.getElementById(`map-property-${id}`)?.scrollIntoView({
                            behavior: "smooth",
                            block: "nearest",
                          });
                        }, 0);
                      }}
                    />
                  </div>
                ) : (
                  <>
                    <div className="property-grid two-cols">
                      {result!.content.map((p) => (
                        <PropertyCard property={p} key={p.id} />
                      ))}
                    </div>
                    <Pagination
                      current={result!.currentPage}
                      total={result!.totalPages}
                      onPage={(p) => update("page", String(p))}
                    />
                  </>
                )}
              </>
            )}
          </section>
        </div>
      </div>
    </div>
  );
}

export function LoadingGrid() {
  return (
    <div className="property-grid two-cols" aria-label="Đang tải">
      <div className="skeleton-card" />
      <div className="skeleton-card" />
      <div className="skeleton-card" />
      <div className="skeleton-card" />
    </div>
  );
}
function Pagination({
  current,
  total,
  onPage,
}: {
  current: number;
  total: number;
  onPage: (n: number) => void;
}) {
  if (total < 2) return null;
  return (
    <nav className="pagination" aria-label="Phân trang">
      <button
        disabled={current <= 1}
        onClick={() => onPage(current - 1)}
        aria-label="Trang trước"
      >
        <ChevronLeft />
      </button>
      {Array.from({ length: Math.min(total, 5) }, (_, i) => i + 1).map((n) => (
        <button
          className={n === current ? "active" : ""}
          onClick={() => onPage(n)}
          key={n}
        >
          {n}
        </button>
      ))}
      <button
        disabled={current >= total}
        onClick={() => onPage(current + 1)}
        aria-label="Trang sau"
      >
        <ChevronRight />
      </button>
    </nav>
  );
}

