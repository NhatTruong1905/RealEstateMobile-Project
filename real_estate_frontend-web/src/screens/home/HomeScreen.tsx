import { useEffect, useState } from "react";
import type { FormEvent } from "react";
import { ArrowRight, Building2, Compass, House, KeyRound, Search } from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "../../services/api/client";
import { PropertyCard } from "../../components/property/PropertyCard";
import type { Property } from "../../types";

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

export function HomePage() {
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

