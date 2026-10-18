import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import {
  BrowserRouter,
  Link,
  Navigate,
  Route,
  Routes,
  useNavigate,
  useParams,
  useSearchParams,
} from "react-router-dom";
import {
  ArrowRight,
  Bath,
  BedDouble,
  Bookmark,
  Building2,
  ChevronLeft,
  ChevronRight,
  CircleUserRound,
  Compass,
  Heart,
  House,
  KeyRound,
  Layers3,
  LoaderCircle,
  List,
  LogOut,
  Map as MapIcon,
  MapPin,
  MessageCircle,
  Phone,
  Search,
  SlidersHorizontal,
  Sparkles,
  Upload,
  X,
} from "lucide-react";
import { api, session } from "./api";
import { Logo } from "./components/brand/Logo";
import { PropertyCard } from "./components/property/PropertyCard";
import { PropertyMap } from "./components/property/PropertyMap";
import { fallbackPropertyImage } from "./config/assets";
import { PublicLayout } from "./layouts/PublicLayout";
import { SellerLayout } from "./layouts/SellerLayout";
import { FAQPage, PrivacyPage, TermsPage } from "./pages/support/SupportPages";
import { ProtectedRoute as Protected } from "./routes/ProtectedRoute";
import type { Property, PropertyPage, UserProfile } from "./types";
import { formatMoney } from "./utils/format";
import "./App.css";

const districts = [
  "Quận 1",
  "Quận 2",
  "Quận 3",
  "Quận 7",
  "Bình Thạnh",
  "Thủ Đức",
];

function SearchBar({ compact = false }: { compact?: boolean }) {
  const navigate = useNavigate();
  const [term, setTerm] = useState("");
  const [type, setType] = useState("");
  function submit(e: FormEvent) {
    e.preventDefault();
    const q = new URLSearchParams();
    if (term) q.set("title", term);
    if (type) q.set("typeId", type);
    navigate(`/properties?${q}`);
  }
  return (
    <form
      className={compact ? "search-bar compact" : "search-bar"}
      onSubmit={submit}
    >
      <label className="search-field">
        <span className="sr-only">Từ khóa hoặc khu vực</span>
        <Search />
        <input
          value={term}
          onChange={(e) => setTerm(e.target.value)}
          placeholder="Tìm theo tên, đường hoặc khu vực"
        />
      </label>
      <label className="search-select">
        <span className="sr-only">Nhu cầu</span>
        <select value={type} onChange={(e) => setType(e.target.value)}>
          <option value="">Mua & thuê</option>
          <option value="1">Mua nhà</option>
          <option value="2">Thuê nhà</option>
        </select>
      </label>
      <button className="button button-accent" type="submit">
        Tìm kiếm <ArrowRight />
      </button>
    </form>
  );
}

function HomePage() {
  const [data, setData] = useState<Property[]>([]);
  useEffect(() => {
    const q = new URLSearchParams({ page: "1", limit: "6" });
    api
      .properties(q)
      .then((r) => setData(r.content))
      .catch(() => {});
  }, []);
  return (
    <>
      <section className="hero-section">
        <div className="hero-noise" />
        <div className="container hero-grid">
          <div className="hero-copy">
            <div className="eyebrow">Không gian đúng. Quyết định đúng.</div>
            <h1>
              Tìm một nơi
              <br />
              để <em>thuộc về.</em>
            </h1>
            <p>
              Khám phá bất động sản phù hợp với nhịp sống của bạn — thông tin rõ
              ràng, hình ảnh trực quan, kết nối trực tiếp.
            </p>
            <SearchBar />
            <div className="quick-links">
              <span>Tìm nhanh:</span>
              {districts.slice(0, 4).map((d) => (
                <Link
                  key={d}
                  to={`/properties?address=${encodeURIComponent(d)}`}
                >
                  {d}
                </Link>
              ))}
            </div>
          </div>
          <div className="hero-visual">
            <img
              src="https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1200&q=85"
              alt="Không gian phòng khách hiện đại, nhiều ánh sáng"
            />
            <div className="hero-caption">
              <span>01</span>
              <div>
                <strong>Nhà phố hiện đại</strong>
                <small>Không gian sống được tuyển chọn</small>
              </div>
            </div>
            <div className="hero-stamp">
              KHÁM PHÁ
              <br />
              NHÀ VIỆT
            </div>
          </div>
        </div>
      </section>
      <section
        className="category-strip container"
        aria-label="Tìm theo loại hình"
      >
        <Link to="/properties?categoryId=1">
          <Building2 />
          <span>
            <strong>Căn hộ</strong>
            <small>Không gian tiện nghi</small>
          </span>
        </Link>
        <Link to="/properties?categoryId=2">
          <House />
          <span>
            <strong>Nhà riêng</strong>
            <small>Chốn ở riêng tư</small>
          </span>
        </Link>
        <Link to="/properties?categoryId=3">
          <Compass />
          <span>
            <strong>Đất</strong>
            <small>Cơ hội dài hạn</small>
          </span>
        </Link>
        <Link to="/properties?typeId=2">
          <KeyRound />
          <span>
            <strong>Cho thuê</strong>
            <small>Linh hoạt chuyển vào</small>
          </span>
        </Link>
      </section>
      <section className="section container">
        <SectionHeading
          index="02"
          eyebrow="Bất động sản dành cho bạn"
          title="Những lựa chọn đáng chú ý"
          action={
            <Link to="/properties">
              Xem tất cả <ArrowRight />
            </Link>
          }
        />
        {data.length ? (
          <div className="property-grid">
            {data.map((p) => (
              <PropertyCard property={p} key={p.id} />
            ))}
          </div>
        ) : (
          <div className="editorial-empty">
            <div>
              <Building2 />
            </div>
            <h3>Đang kết nối kho tin</h3>
            <p>
              Khởi động backend để xem các bất động sản mới nhất từ hệ thống.
            </p>
            <Link className="button button-secondary" to="/properties">
              Mở trang tìm kiếm
            </Link>
          </div>
        )}
      </section>
      <section className="locations-section">
        <div className="container">
          <SectionHeading
            index="03"
            eyebrow="Khám phá theo địa điểm"
            title="Mỗi thành phố, một nhịp sống"
          />
          <div className="location-grid">
            <Link
              to="/properties?address=Hồ Chí Minh"
              className="location-feature"
            >
              <img
                src="https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1200&q=82"
                alt="Thành phố Hồ Chí Minh"
              />
              <span>
                <strong>TP. Hồ Chí Minh</strong>
                <small>Nhịp sống năng động</small>
              </span>
            </Link>
            <Link to="/properties?address=Hà Nội">
              <img
                src="https://images.unsplash.com/photo-1509030450996-dd1a26dda07a?auto=format&fit=crop&w=800&q=82"
                alt="Hà Nội"
              />
              <span>
                <strong>Hà Nội</strong>
                <small>Giá trị bền vững</small>
              </span>
            </Link>
            <Link to="/properties?address=Đà Nẵng">
              <img
                src="https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=800&q=82"
                alt="Đà Nẵng"
              />
              <span>
                <strong>Đà Nẵng</strong>
                <small>Sống gần thiên nhiên</small>
              </span>
            </Link>
          </div>
        </div>
      </section>
      <section className="manifesto">
        <div className="container manifesto-grid">
          <div>
            <span className="eyebrow light">Tìm nhà theo cách dễ hiểu hơn</span>
            <h2>Mỗi lựa chọn bắt đầu từ điều quan trọng nhất.</h2>
          </div>
          <div className="principles">
            <article>
              <span>01</span>
              <h3>Thông tin mạch lạc</h3>
              <p>
                Giá, diện tích, vị trí và thông số được đặt đúng thứ tự bạn cần.
              </p>
            </article>
            <article>
              <span>02</span>
              <h3>Kết nối trực tiếp</h3>
              <p>
                Liên hệ chủ tin từ trang chi tiết khi thông tin đã sẵn sàng.
              </p>
            </article>
            <article>
              <span>03</span>
              <h3>Tìm kiếm có ngữ cảnh</h3>
              <p>
                Bộ lọc được lưu trên URL để bạn quay lại mà không mất lựa chọn.
              </p>
            </article>
          </div>
        </div>
      </section>
    </>
  );
}

function SectionHeading({
  index,
  eyebrow,
  title,
  action,
}: {
  index: string;
  eyebrow: string;
  title: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="section-heading">
      <div className="section-index">{index}</div>
      <div>
        <span className="eyebrow">{eyebrow}</span>
        <h2>{title}</h2>
      </div>
      {action && <div className="section-action">{action}</div>}
    </div>
  );
}

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

function PropertiesPage() {
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
    setStatus("loading");
    api
      .properties(q)
      .then((r) => {
        setResult(r);
        setStatus("ready");
      })
      .catch(() => setStatus("error"));
  }, [query]);
  function update(key: string, value: string) {
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

function LoadingGrid() {
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

function PropertyDetailPage() {
  const { id = "" } = useParams();
  const [property, setProperty] = useState<Property>();
  const [error, setError] = useState("");
  useEffect(() => {
    api
      .property(id)
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

function AuthPage({ mode }: { mode: "login" | "register" }) {
  const navigate = useNavigate();
  const [search] = useSearchParams();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const returnQuery = search.toString();
  const switchPath = `${mode === "login" ? "/register" : "/login"}${returnQuery ? `?${returnQuery}` : ""}`;
  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setBusy(true);
    setError("");
    const data = Object.fromEntries(new FormData(e.currentTarget));
    try {
      if (mode === "login") {
        await api.login(String(data.username), String(data.password));
        const pendingProperty = Number(search.get("saveProperty"));
        if (pendingProperty) await api.setFavorite(pendingProperty, true);
        navigate(search.get("returnTo") || "/");
      } else {
        await api.register(
          Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v)]),
          ),
        );
        navigate(`/login${returnQuery ? `?${returnQuery}` : ""}`);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Có lỗi xảy ra");
    } finally {
      setBusy(false);
    }
  }
  return (
    <div className={mode === "register" ? "auth-page auth-register" : "auth-page auth-login"}>
      <div className="auth-art">
        <div className="auth-art-copy">
          <Logo />
          <p className="display-quote" key={mode}>
            {mode === "login"
              ? "“Một không gian tốt mở ra một chương sống mới.”"
              : "“Bắt đầu hành trình tìm nơi thuộc về bạn.”"}
          </p>
          <span>Nhà Việt · 2026</span>
        </div>
      </div>
      <div className="auth-form-wrap">
        <Link className="back-link" to="/">
          <ChevronLeft /> Về trang chủ
        </Link>
        <form className="auth-form" onSubmit={submit} key={mode}>
          <span className="eyebrow">
            {mode === "login" ? "Chào mừng trở lại" : "Bắt đầu với Nhà Việt"}
          </span>
          <h1>{mode === "login" ? "Đăng nhập" : "Tạo tài khoản"}</h1>
          <p>
            {mode === "login"
              ? "Quản lý tin đã lưu và kết nối với chủ nhà."
              : "Lưu lựa chọn, liên hệ và đăng tin bất động sản."}
          </p>
          {error && (
            <div className="form-error" role="alert">
              {error}
            </div>
          )}
          {mode === "register" && (
            <label>
              Họ và tên
              <input name="fullname" required autoComplete="name" />
            </label>
          )}
          <label>
            Tên đăng nhập
            <input
              name="username"
              required
              minLength={3}
              autoComplete="username"
            />
          </label>
          {mode === "register" && (
            <>
              <label>
                Email
                <input type="email" name="email" autoComplete="email" />
              </label>
              <label>
                Số điện thoại
                <input
                  name="phone"
                  required
                  pattern="0[0-9]{9}"
                  autoComplete="tel"
                />
              </label>
            </>
          )}
          <label>
            Mật khẩu
            <input
              type="password"
              name="password"
              required
              minLength={6}
              autoComplete={
                mode === "login" ? "current-password" : "new-password"
              }
            />
          </label>
          {mode === "login" && (
            <Link className="forgot-link" to="/forgot-password">
              Quên mật khẩu?
            </Link>
          )}
          <button className="button button-primary full" disabled={busy}>
            {busy ? (
              <>
                <LoaderCircle className="spin" /> Đang xử lý
              </>
            ) : mode === "login" ? (
              "Đăng nhập"
            ) : (
              "Tạo tài khoản"
            )}
          </button>
          <p className="auth-switch">
            {mode === "login" ? "Chưa có tài khoản?" : "Đã có tài khoản?"}{" "}
            <Link to={switchPath}>
              {mode === "login" ? "Đăng ký" : "Đăng nhập"}
            </Link>
          </p>
        </form>
      </div>
    </div>
  );
}

function SavedPage() {
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

function AccountPage() {
  const [profile, setProfile] = useState<UserProfile>();
  useEffect(() => {
    api.profile().then(setProfile);
  }, []);
  return (
    <div className="page-shell">
      <div className="container narrow">
        <div className="page-intro compact-intro">
          <span className="eyebrow">Tài khoản</span>
          <h1>Hồ sơ của bạn</h1>
        </div>
        <div className="profile-card">
          <div className="avatar">
            {profile?.avatar ? (
              <img src={profile.avatar} alt="" />
            ) : (
              <CircleUserRound />
            )}
          </div>
          <div>
            <h2>{profile?.fullname || "Đang tải..."}</h2>
            <p>@{profile?.username}</p>
          </div>
          <dl>
            <div>
              <dt>Email</dt>
              <dd>{profile?.email || "Chưa cập nhật"}</dd>
            </div>
            <div>
              <dt>Số điện thoại</dt>
              <dd>{profile?.phone || "Chưa cập nhật"}</dd>
            </div>
          </dl>
          <button
            className="button button-secondary"
            onClick={() => {
              session.clear();
              location.href = "/";
            }}
          >
            <LogOut /> Đăng xuất
          </button>
        </div>
      </div>
    </div>
  );
}

function SellerOverview() {
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
              <SellerPropertyRow key={p.id} p={p} />
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
function SellerPropertyRow({ p }: { p: Property }) {
  return (
    <div className="seller-row">
      <img src={p.images?.[0] || p.image || fallbackPropertyImage} alt="" />
      <div>
        <h3>{p.title}</h3>
        <p>{p.address || p.city || "Chưa cập nhật địa chỉ"}</p>
      </div>
      <strong>{formatMoney(p.price)}</strong>
      <span className="status-pill">{p.status || "Chưa rõ"}</span>
    </div>
  );
}
function SellerProperties() {
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
        <SellerPropertyRow key={p.id} p={p} />
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
function PostProperty() {
  return (
    <div>
      <div className="seller-header">
        <div>
          <span className="eyebrow">Thông tin bất động sản</span>
          <h1>Đăng tin mới</h1>
        </div>
      </div>
      <form className="property-form" onSubmit={(e) => e.preventDefault()}>
        <div className="form-section">
          <span>01</span>
          <div>
            <h2>Thông tin chính</h2>
            <p>Cho người xem biết bạn đang cung cấp điều gì.</p>
          </div>
          <div className="form-fields">
            <label>
              Tiêu đề
              <input
                required
                placeholder="Ví dụ: Căn hộ 2 phòng ngủ nhiều ánh sáng"
              />
            </label>
            <div className="filter-row">
              <label>
                Hình thức
                <select>
                  <option>Mua bán</option>
                  <option>Cho thuê</option>
                </select>
              </label>
              <label>
                Loại bất động sản
                <select>
                  <option>Căn hộ</option>
                  <option>Nhà phố</option>
                  <option>Đất</option>
                </select>
              </label>
            </div>
            <label>
              Mô tả
              <textarea
                rows={6}
                placeholder="Mô tả không gian, tiện ích và điểm nổi bật..."
              />
            </label>
          </div>
        </div>
        <div className="form-section">
          <span>02</span>
          <div>
            <h2>Giá và thông số</h2>
            <p>Các trường bắt buộc theo API hiện tại.</p>
          </div>
          <div className="form-fields">
            <div className="filter-row">
              <label>
                Giá (VNĐ)
                <input type="number" min="1" required />
              </label>
              <label>
                Diện tích (m²)
                <input type="number" min="1" required />
              </label>
            </div>
            <div className="triple-row">
              <label>
                Phòng ngủ
                <input type="number" min="0" />
              </label>
              <label>
                Phòng tắm
                <input type="number" min="0" />
              </label>
              <label>
                Số tầng
                <input type="number" min="0" />
              </label>
            </div>
          </div>
        </div>
        <div className="form-section">
          <span>03</span>
          <div>
            <h2>Vị trí và hình ảnh</h2>
            <p>Ảnh rõ nét giúp người xem đánh giá tốt hơn.</p>
          </div>
          <div className="form-fields">
            <label>
              Địa chỉ
              <input required />
            </label>
            <label>
              Thông tin pháp lý
              <input required placeholder="Nhập đúng thông tin được xác nhận" />
            </label>
            <label className="upload-box">
              <Upload />
              <strong>Chọn ảnh bất động sản</strong>
              <small>JPG, PNG theo giới hạn backend</small>
              <input type="file" multiple accept="image/png,image/jpeg" />
            </label>
          </div>
        </div>
        <div className="form-actions">
          <button className="button button-primary" type="submit">
            Lưu tin đăng
          </button>
          <p>
            Form đã sẵn sàng về giao diện; danh mục động và xác nhận upload cần
            dữ liệu API tương ứng.
          </p>
        </div>
      </form>
    </div>
  );
}

function SimplePage({
  type,
}: {
  type: "forgot" | "messages" | "customers";
}) {
  const content = {
    forgot: [
      "Khôi phục tài khoản",
      "Luồng OTP sẽ kết nối với các endpoint khôi phục hiện có.",
    ],
    messages: [
      "Tin nhắn",
      "Kết nối chat thời gian thực đang chờ hoàn thiện hợp đồng WebSocket.",
    ],
    customers: [
      "Khách hàng quan tâm",
      "Danh sách được hiển thị khi dữ liệu interaction được kết nối.",
    ],
  }[type];
  return (
    <div className="page-shell">
      <div className="container narrow">
        <div className="page-intro compact-intro">
          <span className="eyebrow">Nhà Việt</span>
          <h1>{content[0]}</h1>
          <p>{content[1]}</p>
        </div>
        <State
          icon={type === "messages" ? <MessageCircle /> : <Sparkles />}
          title="Đang chuẩn bị nội dung"
          text="Khu vực này được giữ trung thực với trạng thái tích hợp hiện tại, không dùng dữ liệu minh họa thay cho dữ liệu thật."
          action={
            <Link className="button button-secondary" to="/">
              Về trang chủ
            </Link>
          }
        />
      </div>
    </div>
  );
}
function NotFound() {
  return (
    <div className="not-found">
      <strong>404</strong>
      <span className="eyebrow">Đường dẫn không tồn tại</span>
      <h1>Có vẻ bạn đã rẽ nhầm.</h1>
      <p>Hãy quay về trang chủ hoặc tiếp tục khám phá kho bất động sản.</p>
      <div>
        <Link className="button button-primary" to="/">
          Về trang chủ
        </Link>
        <Link className="button button-secondary" to="/properties">
          Xem bất động sản
        </Link>
      </div>
    </div>
  );
}
function State({
  icon,
  title,
  text,
  action,
}: {
  icon: React.ReactNode;
  title: string;
  text: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="state">
      <div className="state-icon">{icon}</div>
      <h2>{title}</h2>
      <p>{text}</p>
      {action}
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<PublicLayout />}>
          <Route index element={<HomePage />} />
          <Route path="properties" element={<PropertiesPage />} />
          <Route path="properties/:id" element={<PropertyDetailPage />} />
          <Route
            path="saved"
            element={
              <Protected>
                <SavedPage />
              </Protected>
            }
          />
          <Route
            path="account"
            element={
              <Protected>
                <AccountPage />
              </Protected>
            }
          />
          <Route
            path="messages"
            element={
              <Protected>
                <SimplePage type="messages" />
              </Protected>
            }
          />
          <Route path="faq" element={<FAQPage />} />
          <Route path="terms" element={<TermsPage />} />
          <Route path="privacy" element={<PrivacyPage />} />
          <Route
            path="forgot-password"
            element={<SimplePage type="forgot" />}
          />
        </Route>
        <Route path="login" element={<AuthPage mode="login" />} />
        <Route path="register" element={<AuthPage mode="register" />} />
        <Route
          path="seller"
          element={
            <Protected>
              <SellerLayout />
            </Protected>
          }
        >
          <Route path="overview" element={<SellerOverview />} />
          <Route path="properties" element={<SellerProperties />} />
          <Route path="post" element={<PostProperty />} />
          <Route path="customers" element={<SimplePage type="customers" />} />
          <Route index element={<Navigate to="overview" replace />} />
        </Route>
        <Route path="*" element={<NotFound />} />
      </Routes>
    </BrowserRouter>
  );
}
