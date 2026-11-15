import { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { ChevronLeft, ChevronRight, House, LoaderCircle, Plus } from "lucide-react";
import { sellerApi } from "../../services/api/seller/sellerApi";
import type { PropertyPage } from "../../types";
import { Link } from "../../components/ui/Navigation";
import { SellerPropertyRow } from "../../components/property/SellerPropertyRow";
import { State } from "../../components/ui/State";

export function SellerProperties() {
  const [params, setParams] = useSearchParams();
  const requestedPage = Number(params.get("page") || 1);
  const page = Number.isInteger(requestedPage) && requestedPage > 0 ? requestedPage : 1;
  const requestedLimit = Number(params.get("limit") || 6);
  const limit = [6, 12, 24].includes(requestedLimit) ? requestedLimit : 6;
  const [retry, setRetry] = useState(0);
  const requestKey = `${page}:${limit}:${retry}`;
  const [result, setResult] = useState<{ key: string; data?: PropertyPage; error?: string }>();
  const loading = result?.key !== requestKey;
  const data = loading ? undefined : result?.data;

  useEffect(() => {
    let active = true;
    sellerApi.listMyPropertiesPage(page, limit).then((data) => {
      if (!active) return;
      const lastPage = Math.max(1, data.totalPages);
      if (page > lastPage) {
        setParams((current) => { const next = new URLSearchParams(current); next.set("page", String(lastPage)); return next; }, { replace: true });
        return;
      }
      setResult({ key: requestKey, data });
    }).catch((error: unknown) => {
      if (active) setResult({ key: requestKey, error: error instanceof Error ? error.message : "Không tải được tin đăng." });
    });
    return () => { active = false; };
  }, [page, limit, requestKey, setParams]);

  function pageUrl(nextPage: number) {
    const next = new URLSearchParams(params);
    next.set("page", String(nextPage));
    next.set("limit", String(limit));
    return `?${next}`;
  }
  const pages = data ? [...new Set([1, page - 1, page, page + 1, data.totalPages])]
    .filter((value) => value >= 1 && value <= data.totalPages).sort((a, b) => a - b) : [];

  return (
    <div>
      <div className="seller-header">
        <div><span className="eyebrow">Quản lý nội dung</span><h1>Tin đăng</h1></div>
        <Link className="button button-primary" to="/seller/post">Đăng tin mới <Plus aria-hidden="true" /></Link>
      </div>
      <div className="seller-list-toolbar">
        <p role="status">{data ? data.totalItems > 0
          ? `Hiển thị ${(page - 1) * limit + 1}–${Math.min(page * limit, data.totalItems)} / ${data.totalItems} tin`
          : "Chưa có tin đăng" : loading ? "Đang tải danh sách…" : "Không tải được danh sách"}</p>
        <label>Số tin mỗi trang
          <select value={limit} disabled={loading} onChange={(event) => {
            const next = new URLSearchParams(params);
            next.set("limit", event.target.value); next.set("page", "1"); setParams(next);
          }}>{[6, 12, 24].map((size) => <option key={size} value={size}>{size} tin</option>)}</select>
        </label>
      </div>
      <section className="seller-page-results" aria-label="Danh sách tin của tôi" aria-busy={loading}>
        {loading ? <p className="seller-list-loading"><LoaderCircle className="spin" aria-hidden="true" /> Đang tải tin đăng...</p>
          : result?.error ? <div role="alert"><p>{result.error}</p><button className="button button-secondary" onClick={() => setRetry((value) => value + 1)}>Tải lại</button></div>
          : data?.content.length ? <div className="seller-list">{data.content.map((property) => <SellerPropertyRow key={property.id} property={property} />)}</div>
          : <State icon={<House />} title="Chưa có tin nào" text="Tin do bạn đăng sẽ xuất hiện ở đây." />}
      </section>
      {data && data.totalPages > 1 && <nav className="seller-pagination" aria-label="Phân trang tin đăng">
        {page > 1 ? <Link to={pageUrl(page - 1)} aria-label="Trang trước"><ChevronLeft size={18} /></Link> : <span aria-disabled="true" aria-label="Trang trước"><ChevronLeft size={18} /></span>}
        {pages.map((value, index) => <span className="seller-pagination-item" key={value}>
          {index > 0 && value - pages[index - 1] > 1 && <span className="seller-page-gap" aria-hidden="true">…</span>}
          {value === page ? <span className="current" aria-current="page" aria-label={`Trang ${value}`}>{value}</span> : <Link to={pageUrl(value)} aria-label={`Trang ${value}`}>{value}</Link>}
        </span>)}
        {page < data.totalPages ? <Link to={pageUrl(page + 1)} aria-label="Trang sau"><ChevronRight size={18} /></Link> : <span aria-disabled="true" aria-label="Trang sau"><ChevronRight size={18} /></span>}
      </nav>}
    </div>
  );
}
