import { useEffect, useRef, useState, type FormEvent } from "react";
import { useParams } from "react-router-dom";
import { ArrowLeft, ArrowRight, Check, CheckCircle2, ChevronDown, ImagePlus, MapPin, Pencil, RefreshCw, ShieldCheck, Trash2 } from "lucide-react";
import { Link } from "../../components/ui/Navigation";
import {
  sellerApi,
  type PropertyOptions,
  type PropertyOption,
} from "../../services/api/seller/sellerApi";
import { ApiError } from "../../services/api/core/http";
import { receivedMessage, statusLabel } from "../../utils/format";
import type { Property } from "../../types";
import { resizePropertyImage } from "../../utils/propertyImage";
import { LoadingButton } from "../../components/ui/LoadingButton";
import { validatePropertyFormData } from "../../utils/propertyValidation";

const steps = ["Thông tin", "Hình ảnh", "Kiểm tra"];
function PhotoImage({ file, alt }: { file: File; alt: string }) {
  const [source, setSource] = useState("");
  useEffect(() => {
    if (!URL.createObjectURL) return;
    const url = URL.createObjectURL(file);
    setSource(url);
    return () => URL.revokeObjectURL(url);
  }, [file]);
  return source ? <img src={source} alt={alt} /> : <span className="post-photo-loading" role="img" aria-label={alt}><ImagePlus aria-hidden="true" /></span>;
}

export function EditRejectedProperty() {
  const { id } = useParams();
  const [result, setResult] = useState<{ id: string | undefined; property?: Property; error?: string }>();
  useEffect(() => {
    let active = true;
    const propertyId = Number(id);
    if (!Number.isSafeInteger(propertyId) || propertyId < 1) {
      return;
    }
    sellerApi.get(propertyId)
      .then((property) => { if (active) setResult({ id, property }); })
      .catch((error: Error) => { if (active) setResult({ id, error: error.message }); });
    return () => { active = false; };
  }, [id]);
  const invalid = !id || !/^[1-9]\d*$/.test(id) || !Number.isSafeInteger(Number(id));
  const current = result?.id === id ? result : undefined;
  if (!invalid && !current) return <p role="status">Đang tải tin đăng...</p>;
  if (current?.property?.status === "Từ chối") {
    return <PostProperty key={id} revision={current.property} />;
  }
  return (
    <div className="post-notice">
      <p role="alert">{current?.error || "Chỉ có thể sửa và gửi lại tin đang bị từ chối."}</p>
      <Link className="text-link" to="/seller/properties">Về danh sách tin</Link>
    </div>
  );
}

function initialFields(property?: Property): Record<string, string> {
  if (!property) return {};
  const names = ["title", "price", "area", "typeId", "categoryId", "address", "city", "wardId", "legal",
    "bedroomCount", "bathroomCount", "floorCount", "direction", "description"] as const;
  return Object.fromEntries(names.map((name) => [name, String(property[name] ?? "")]));
}

export function PostProperty({ revision }: { revision?: Property } = {}) {
  const [step, setStep] = useState(0);
  const [values, setValues] = useState(() => initialFields(revision));
  const [existingImages, setExistingImages] = useState(() => revision?.images ?? []);
  const [fields, setFields] = useState<Record<string, string>>({});
  const [photos, setPhotos] = useState<File[]>([]);
  const [photoError, setPhotoError] = useState("");
  const [detailsOpen, setDetailsOpen] = useState(Boolean(revision));
  const formRef = useRef<HTMLFormElement>(null);
  const headingRef = useRef<HTMLHeadingElement>(null);
  const focusStep = useRef(false);
  const focusField = useRef("");
  const validated = useRef(false);
  useEffect(() => {
    if (!focusStep.current) return;
    if (focusField.current) {
      (formRef.current?.elements.namedItem(focusField.current) as HTMLElement | null)?.focus();
      focusField.current = "";
    } else headingRef.current?.focus();
    focusStep.current = false;
  }, [step, fields]);
  function goTo(next: number) {
    focusStep.current = true;
    setStep(next);
  }
  function addPhotos(selected: FileList | null) {
    const incoming = Array.from(selected || []);
    if (!incoming.length) return;
    if (incoming.some((file) => !file.size || !["image/jpeg", "image/png"].includes(file.type))) {
      setPhotoError("Chỉ chọn ảnh JPG hoặc PNG có dung lượng lớn hơn 0.");
      return;
    }
    const unique = incoming.filter((file) => !photos.some((old) => old.name === file.name && old.size === file.size && old.lastModified === file.lastModified));
    if (existingImages.length + photos.length + unique.length > 5) { setPhotoError("Chỉ giữ tối đa 5 ảnh, tính cả ảnh hiện có."); return; }
    setPhotos((current) => [...current, ...unique]);
    setPhotoError("");
    setFields((current) => { const next = { ...current }; delete next.files; return next; });
  }
  const submitting = useRef(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [saved, setSaved] = useState<Property>();
  const [options, setOptions] = useState<PropertyOptions>();
  const [optionsError, setOptionsError] = useState("");
  const [optionsLoading, setOptionsLoading] = useState(true);
  function loadOptions() {
    setOptionsLoading(true);
    sellerApi
      .options()
      .then((value) => {
        setOptions(value);
        setOptionsError("");
      })
      .catch((e: Error) => setOptionsError(e.message))
      .finally(() => setOptionsLoading(false));
  }
  useEffect(() => {
    let active = true;
    sellerApi
      .options()
      .then((value) => {
        if (active) setOptions(value);
      })
      .catch((e: Error) => {
        if (active) setOptionsError(e.message);
      })
      .finally(() => {
        if (active) setOptionsLoading(false);
      });
    return () => {
      active = false;
    };
  }, []);
  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (submitting.current) return;
    if (!options || optionsLoading || optionsError) return;
    const data = new FormData(event.currentTarget);
    validated.current = true;
    const invalidNumbers = new Set(Array.from(event.currentTarget.elements)
      .filter((input): input is HTMLInputElement => input instanceof HTMLInputElement && input.validity.badInput)
      .map((input) => input.name));
    const errors = validatePropertyFormData(data, options, invalidNumbers);
    const files = photos;
    if (step > 0 && photoError) errors.files = photoError;
    if (files.length > 5) errors.files = "Chỉ chọn tối đa 5 ảnh.";
    if (files.some((file) => !["image/jpeg", "image/png"].includes(file.type)))
      errors.files = "Chỉ chọn ảnh JPG hoặc PNG.";
    data.delete("files");
    setFields(errors);
    setError("");
    if (Object.keys(errors).length) {
      const first = Object.keys(errors).find((name) => name !== "files");
      focusField.current = first || "";
      goTo(first ? 0 : 1);
      return;
    }
    if (step < 2) {
      setValues(Object.fromEntries(Array.from(data.entries()).filter((entry): entry is [string, string] => typeof entry[1] === "string")));
      goTo(step + 1);
      return;
    }
    submitting.current = true;
    setLoading(true);
    try {
      for (const file of files) data.append("files", await resizePropertyImage(file));
      if (revision?.images?.length && existingImages.length !== revision.images.length) {
        if (existingImages.length) existingImages.forEach((image) => data.append("images", image));
        else data.set("images", "");
      }
      setSaved(await (revision ? sellerApi.saveRejectedDraft(revision.id, data) : sellerApi.create(data)));
    } catch (failure) {
      setError(
        failure instanceof TypeError
          ? "Lỗi kết nối. Hãy kiểm tra Tin đăng trước khi thử lại để tránh tạo trùng."
          : failure instanceof Error
            ? failure.message
            : "Lỗi kết nối. Kiểm tra Tin đăng trước khi thử lại.",
      );
      if (failure instanceof ApiError) {
        const fieldErrors = Object.fromEntries(Object.entries(failure.fields)
          .filter(([name]) => name === "files" || formRef.current?.elements.namedItem(name)));
        setFields(fieldErrors);
        if (Object.keys(fieldErrors).length) {
          const first = Object.keys(fieldErrors).find((name) => name !== "files");
          focusField.current = first || "";
          goTo(first ? 0 : 1);
        }
      }
    } finally {
      submitting.current = false;
      setLoading(false);
    }
  }
  async function resubmit() {
    if (!saved || submitting.current) return;
    submitting.current = true;
    setLoading(true);
    setError("");
    try {
      setSaved(await sellerApi.resubmit(saved.id));
    } catch (failure) {
      setError(failure instanceof Error ? failure.message : "Chưa thể gửi lại tin.");
    } finally {
      submitting.current = false;
      setLoading(false);
    }
  }
  if (saved) {
    const draft = Boolean(revision) && saved.status === "Từ chối";
    const pending = saved.status === "Chờ duyệt";
    const heading = draft ? "Đã lưu chỉnh sửa" : revision ? "Đã gửi lại để xét duyệt" : "Đã tiếp nhận tin";
    return (
      <section className="post-success" aria-labelledby="post-success-heading">
        <div className="post-success-summary" role="status">
          <span className="post-success-icon"><CheckCircle2 size={26} aria-hidden="true" /></span>
          <div>
            <h1 id="post-success-heading">{heading}</h1>
            <p>{draft
              ? "Bản chỉnh sửa đã được lưu. Khi sẵn sàng, hãy gửi lại tin để được xét duyệt."
              : pending ? receivedMessage : "Bạn có thể xem tin trong danh sách bài đăng của mình."}</p>
          </div>
        </div>
        <dl className="post-success-details">
          <div><dt>Mã tin</dt><dd>#{saved.id}</dd></div>
          <div><dt>Trạng thái hiện tại</dt><dd>
            <span className={`listing-review-badge ${draft ? "is-rejected" : pending ? "is-pending" : ""}`}>
              {statusLabel(saved.status)}
            </span>
          </dd></div>
        </dl>
        {error && <p className="post-submit-error" role="alert">{error}</p>}
        <div className="post-success-actions">
          {draft && (
            <LoadingButton className="button button-primary" type="button" loading={loading}
              loadingLabel="Đang gửi lại…" onClick={() => void resubmit()}>
              Gửi lại để xét duyệt <ArrowRight size={17} aria-hidden="true" />
            </LoadingButton>
          )}
          <Link className={`button ${draft ? "button-secondary" : "button-primary"}`} to="/seller/properties">
            Xem tin đăng của tôi
          </Link>
        </div>
      </section>
    );
  }
  function field(name: string, label: string, type = "text", required = false, placeholder?: string) {
    return (
      <label key={name}>
        <span id={`${name}-label`}>{label}{required && " *"}</span>
        <input
          name={name}
          defaultValue={values[name] ?? ""}
          aria-labelledby={`${name}-label`}
          placeholder={placeholder}
          type={type}
          required={required}
          maxLength={type === "text" ? (["legal", "direction", "city"].includes(name) ? 45 : 255) : undefined}
          max={type === "number" ? (name.endsWith("Count") ? 2147483647 : name === "price" ? 9999999999999.99 : 99999999.99) : undefined}
          min={
            type === "number"
              ? name.endsWith("Count")
                ? "0"
                : "0.01"
              : undefined
          }
          step={name.endsWith("Count") ? "1" : "0.01"}
          aria-invalid={!!fields[name]}
          aria-describedby={`${name}-error`}
        />
        <small id={`${name}-error`} role={fields[name] ? "alert" : undefined}>
          {fields[name]}
        </small>
      </label>
    );
  }
  function select(
    name: string,
    label: string,
    items: PropertyOption[] = [],
    optional = false,
  ) {
    return (
      <label>
        <span id={`${name}-label`}>{label}{!optional && " *"}</span>
        <select
          name={name}
          aria-labelledby={`${name}-label`}
          required={!optional}
          value={values[name] || ""}
          aria-invalid={!!fields[name]}
          aria-describedby={`${name}-error`}
        >
          <option value="">
            {optional ? "Xác định từ địa chỉ" : "Chọn " + label.toLowerCase()}
          </option>
          {items.map((item) => (
            <option key={item.id} value={item.id}>
              {item.name}
              {item.districtName ? ` - ${item.districtName}` : ""}
            </option>
          ))}
        </select>
        <small id={`${name}-error`} role={fields[name] ? "alert" : undefined}>{fields[name]}</small>
      </label>
    );
  }
  const optionName = (name: string, items?: PropertyOption[]) => items?.find((item) => String(item.id) === values[name])?.name || "Chưa chọn";
  const price = Number(values.price);
  const priceText = price > 0 ? `${price.toLocaleString("vi-VN")} ₫` : "Chưa nhập giá";
  return (
    <div className="post-page">
      <header className="post-header">
        <div><h1>{revision ? "Sửa tin bị từ chối" : "Đăng tin mới"}</h1><p>{revision ? `Tin #${revision.id}` : "Giới thiệu bất động sản của bạn, từng bước một."}</p></div>
        <Link className="text-link" to="/seller/properties"><ArrowLeft size={16} /> Tin đăng của tôi</Link>
      </header>
      {revision?.rejectionReason && <div className="post-notice"><p><strong>Lý do từ chối:</strong> {revision.rejectionReason}</p></div>}
      <nav className="post-steps" aria-label="Các bước đăng tin">
        <ol>{steps.map((label, index) => <li key={label} className={index === step ? "current" : index < step ? "complete" : ""}>
          <button type="button" disabled={loading || index > step} aria-current={index === step ? "step" : undefined} onClick={() => goTo(index)}>
            <span>{index < step ? <Check size={16} aria-hidden="true" /> : index + 1}</span>{label}
          </button>
        </li>)}</ol>
      </nav>
      {optionsLoading && !optionsError && <p role="status">Đang tải danh mục...</p>}
      {optionsError && (
        <div className="post-notice">
          <p role="alert">{optionsError}</p>
          <LoadingButton
            className="button button-secondary"
            type="button"
            loading={optionsLoading}
            loadingLabel="Đang tải lại…"
            onClick={loadOptions}
          >
            <RefreshCw size={16} aria-hidden="true" />
            Thử lại
          </LoadingButton>
        </div>
      )}
      <form ref={formRef} className="property-form post-form" noValidate onSubmit={submit}
        onBlur={(event) => {
          const target = event.target;
          if (!options || !formRef.current || !(target instanceof HTMLInputElement || target instanceof HTMLSelectElement || target instanceof HTMLTextAreaElement) || target.type === "file") return;
          const invalidNumbers = new Set(Array.from(formRef.current.elements)
            .filter((input): input is HTMLInputElement => input instanceof HTMLInputElement && input.validity.badInput)
            .map((input) => input.name));
          const updated = validatePropertyFormData(new FormData(formRef.current), options, invalidNumbers);
          setFields((current) => {
            const next = { ...current };
            if (updated[target.name]) next[target.name] = updated[target.name];
            else delete next[target.name];
            return next;
          });
        }}
        onChange={(event) => {
          const target = event.target;
          if (target instanceof HTMLInputElement || target instanceof HTMLSelectElement || target instanceof HTMLTextAreaElement) {
            if (target.type === "file") return;
            setValues((current) => ({ ...current, [target.name]: target.value }));
            if ((validated.current || fields[target.name]) && options && formRef.current) {
              const invalidNumbers = new Set(Array.from(formRef.current.elements)
                .filter((input): input is HTMLInputElement => input instanceof HTMLInputElement && input.validity.badInput)
                .map((input) => input.name));
              const updated = validatePropertyFormData(new FormData(formRef.current), options, invalidNumbers);
              setFields((current) => {
                const next = { ...current };
                if (updated[target.name]) next[target.name] = updated[target.name];
                else delete next[target.name];
                return next;
              });
              setError("");
            }
          }
        }}>
        <fieldset disabled={loading || optionsLoading || !options || !!optionsError}>
          <div className="post-layout">
            <div className="post-editor">
              <div className="post-stage-heading"><h2 ref={headingRef} tabIndex={-1}>{["Thông tin bất động sản", "Thêm hình ảnh thực tế", "Kiểm tra trước khi gửi"][step]}</h2>
                <p>{["Các trường có dấu * là bắt buộc. Bạn có thể bổ sung chi tiết bên dưới.", "Chọn tối đa 5 ảnh JPG hoặc PNG. Có thể thêm ảnh nhiều lần và xóa ảnh đã chọn.", "Xem lại nội dung bên dưới. Tin sẽ được gửi tới nhân viên xét duyệt."][step]}</p>
              </div>
              <div hidden={step !== 0} className="post-stage">
                <section className="post-group" aria-labelledby="post-basic">
                  <h3 id="post-basic">Bạn muốn đăng bất động sản nào?</h3>
                  <div className="post-grid">{select("typeId", "Loại hình giao dịch", options?.types)}{select("categoryId", "Phân khúc bất động sản", options?.categories)}</div>
                  {field("title", "Tiêu đề", "text", true, "Ví dụ: Căn hộ 2 phòng ngủ, ban công thoáng tại Quận 7")}
                  <div className="post-grid">{field("price", "Giá (VNĐ)", "number", true, "Ví dụ: 3500000000")}{field("area", "Diện tích (m²)", "number", true, "Ví dụ: 75")}</div>
                  {price > 0 && <p className="post-price-hint">Giá đã nhập: <strong>{priceText}</strong></p>}
                </section>
                <section className="post-group" aria-labelledby="post-location">
                  <h3 id="post-location">Vị trí &amp; pháp lý</h3>
                  {field("address", "Địa chỉ đầy đủ", "text", true, "Số nhà, tên đường, phường/xã, quận/huyện, tỉnh/thành")}
                  {revision && field("city", "Tỉnh/thành phố", "text", false, "Ví dụ: Hồ Chí Minh")}
                  {select("wardId", "Phường/xã", options?.wards, true)}
                  <p className="post-help">Nếu chưa chọn phường/xã, hệ thống sẽ xác định từ địa chỉ. Chọn cụ thể khi địa chỉ chưa xác định được.</p>
                  {field("legal", "Thông tin pháp lý", "text", true, "Ví dụ: Sổ hồng riêng, hợp đồng mua bán…")}
                </section>
                <details className="post-group post-optional" open={detailsOpen || Boolean(fields.floorCount || fields.bedroomCount || fields.bathroomCount || fields.direction || fields.description)} onToggle={(event) => setDetailsOpen(event.currentTarget.open)}>
                  <summary>Mô tả &amp; tiện ích <span>Không bắt buộc</span><ChevronDown size={18} aria-hidden="true" /></summary>
                  <p className="post-help">Không bắt buộc. Thông tin cụ thể giúp người xem đánh giá bất động sản dễ hơn.</p>
                  <div className="post-grid post-grid-three">{field("bedroomCount", "Phòng ngủ", "number")}{field("bathroomCount", "Phòng tắm", "number")}{field("floorCount", "Số tầng", "number")}</div>
                  {field("direction", "Hướng nhà", "text", false, "Ví dụ: Đông Nam")}
                  <label>Mô tả<textarea name="description" defaultValue={values.description ?? ""} rows={5} placeholder="Giới thiệu không gian, nội thất, tiện ích xung quanh và điều kiện giao dịch…" /></label>
                </details>
              </div>
              <div hidden={step !== 1} className="post-stage">
                <label className="post-upload" onDragOver={(event) => event.preventDefault()} onDrop={(event) => { event.preventDefault(); if (!loading) addPhotos(event.dataTransfer.files); }}>
                  <ImagePlus size={36} aria-hidden="true" /><span>Ảnh (tối đa 5 JPG/PNG)</span>
                  <span className="post-upload-action">Chọn ảnh từ thiết bị</span><small>hoặc kéo thả ảnh vào đây</small>
                  <input name="files" type="file" multiple accept="image/png,image/jpeg" aria-describedby="post-photo-error" onChange={(event) => { addPhotos(event.currentTarget.files); event.currentTarget.value = ""; }} />
                </label>
                <p className="post-help">Chọn ảnh sáng, rõ nét: mặt tiền, phòng chính và các tiện ích. Ảnh lớn được tự động thu nhỏ, giữ nguyên tỷ lệ.</p>
                <p id="post-photo-error" role={photoError || fields.files ? "alert" : undefined}>{photoError || fields.files}</p>
                {photoError && <button type="button" className="button button-secondary" onClick={() => { setPhotoError(""); setFields((current) => { const next = { ...current }; delete next.files; return next; }); }}>Bỏ qua lượt chọn này</button>}
                <p className="post-photo-count" role="status">Đã chọn {existingImages.length + photos.length}/5 ảnh</p>
                <div className="post-photos">
                  {existingImages.map((image, index) => (
                    <figure key={image}>
                      <img src={image} alt={`Ảnh hiện có ${index + 1}`} />
                      <figcaption><span>Ảnh hiện có</span><button className="icon-button" type="button"
                        aria-label={`Xóa ảnh hiện có ${index + 1}`} onClick={() => {
                          setExistingImages((current) => current.filter((url) => url !== image));
                          setPhotoError("");
                        }}><Trash2 size={18} aria-hidden="true" /></button></figcaption>
                    </figure>
                  ))}
                  {photos.map((photo, index) => <figure key={`${photo.name}-${photo.lastModified}-${index}`}>
                  <PhotoImage file={photo} alt={`Ảnh đã chọn ${index + 1}`} />
                  <figcaption><span>{photo.name}</span><button className="icon-button" type="button" aria-label={`Xóa ảnh ${index + 1}`} onClick={() => { setPhotos((current) => current.filter((_, i) => i !== index)); setPhotoError(""); setFields((current) => { const next = { ...current }; delete next.files; return next; }); }}><Trash2 size={18} /></button></figcaption>
                </figure>)}</div>
              </div>
              <div hidden={step !== 2} className="post-stage post-review">
                <div className="post-review-title"><h3>{values.title?.trim()}</h3><button type="button" className="text-link" onClick={() => goTo(0)}><Pencil size={16} /> Sửa thông tin</button></div>
                <p className="post-review-price">{priceText}</p>
                <p className="post-review-address"><MapPin size={18} />{values.address}</p>
                <dl className="post-review-facts">{[
                  ["Giao dịch", optionName("typeId", options?.types)], ["Phân khúc", optionName("categoryId", options?.categories)],
                  ["Diện tích", `${values.area || "—"} m²`], ["Phường/xã", values.wardId ? optionName("wardId", options?.wards) : "Xác định từ địa chỉ"],
                  ...(revision ? [["Tỉnh/thành phố", values.city]] : []),
                  ["Pháp lý", values.legal], ["Phòng ngủ", values.bedroomCount], ["Phòng tắm", values.bathroomCount], ["Số tầng", values.floorCount], ["Hướng nhà", values.direction],
                ].map(([label, value]) => <div key={label}><dt>{label}</dt><dd>{value || "Chưa cung cấp"}</dd></div>)}</dl>
                {values.description && <section><h3>Mô tả</h3><p className="post-review-description">{values.description}</p></section>}
                <div className="post-review-title"><h3>Hình ảnh · {existingImages.length + photos.length}/5</h3><button type="button" className="text-link" onClick={() => goTo(1)}><Pencil size={16} /> Sửa hình ảnh</button></div>
                {existingImages.length + photos.length > 0 ? <div className="post-review-photos">
                  {existingImages.map((image, index) => <figure key={image}><img src={image} alt={`Ảnh hiện có ${index + 1}`} /></figure>)}
                  {photos.map((photo, index) => <figure key={index}><PhotoImage file={photo} alt={`Ảnh bất động sản ${index + 1}`} /><figcaption>{photo.name}</figcaption></figure>)}
                </div> : <p className="post-help">Chưa thêm hình ảnh. Bạn vẫn có thể gửi tin.</p>}
                <div className="post-review-notice"><ShieldCheck size={22} /><p>{revision ? "Sau khi lưu chỉnh sửa, bạn có thể gửi lại tin để quản trị viên xét duyệt." : "Tin chưa được công khai ngay. Nhân viên sẽ xét duyệt và thông báo kết quả qua email đăng ký."}</p></div>
              </div>
              {Object.keys(fields).some((name) => name !== "files") && <p className="post-validation-note">Vui lòng kiểm tra các trường được đánh dấu phía trên.</p>}
              {error && <p className="post-submit-error" role="alert">{error}</p>}
              <footer className="post-actions">
                {step > 0 && <button type="button" className="button button-secondary" onClick={() => goTo(step - 1)}><ArrowLeft size={18} /> Quay lại</button>}
                <span className="post-step-caption">Bước {step + 1} / 3</span>
                <LoadingButton className="button button-primary" type="submit" loading={loading} loadingLabel={revision ? "Đang lưu…" : "Đang gửi…"}>{step === 2 ? <>{revision ? "Lưu chỉnh sửa" : "Gửi tin chờ duyệt"} <CheckCircle2 size={18} /></> : <>Tiếp tục: {step === 0 ? "hình ảnh" : "kiểm tra"} <ArrowRight size={18} /></>}</LoadingButton>
              </footer>
            </div>
            <aside className="post-guide" aria-label="Hướng dẫn đăng tin">
              <h2>Một tin đăng rõ ràng, <br />một kết nối phù hợp.</h2>
              <p>{["Bắt đầu với giao dịch, mức giá và vị trí. Các thông tin này giúp người mua tìm thấy tin phù hợp.", "Ảnh thực tế giúp người xem hiểu rõ không gian. Kiểm tra từng ảnh trước khi gửi.", "Bạn đã đến bước cuối. Hãy xác nhận lại giá, địa chỉ và pháp lý trước khi gửi duyệt."][step]}</p>
              <div className="post-guide-divider" />
              <h3>Trước khi hoàn tất</h3>
              <ul><li><Check size={17} /> Giá và diện tích chính xác</li><li><Check size={17} /> Địa chỉ đầy đủ, dễ xác định</li><li><Check size={17} /> Pháp lý mô tả đúng thực tế</li></ul>
              <small>Nội dung được giữ khi quay lại giữa các bước trong phiên điền này.</small>
            </aside>
          </div>
        </fieldset>
      </form>
    </div>
  );
}
