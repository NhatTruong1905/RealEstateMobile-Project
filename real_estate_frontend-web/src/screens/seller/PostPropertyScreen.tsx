import { useEffect, useRef, useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import {
  sellerApi,
  type PropertyOptions,
  type PropertyOption,
} from "../../services/api/seller/sellerApi";
import { ApiError } from "../../services/api/core/http";
import { receivedMessage, statusLabel } from "../../utils/format";
import type { Property } from "../../types";
import { resizePropertyImage } from "../../utils/propertyImage";

export function PostProperty() {
  const submitting = useRef(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [fields, setFields] = useState<Record<string, string>>({});
  const [saved, setSaved] = useState<Property>();
  const [options, setOptions] = useState<PropertyOptions>();
  const [optionsError, setOptionsError] = useState("");
  const [optionsLoading, setOptionsLoading] = useState(true);
  function loadOptions() {
    setOptionsLoading(true);
    setOptionsError("");
    sellerApi
      .options()
      .then(setOptions)
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
    const errors: Record<string, string> = {};
    for (const name of ["title", "address", "legal"]) {
      const value = String(data.get(name) || "").trim();
      data.set(name, value);
      if (!value) errors[name] = "Vui lòng nhập thông tin.";
    }
    for (const name of ["price", "area", "typeId", "categoryId", "wardId"]) {
      const value = String(data.get(name) || "");
      if (name === "wardId" && !value) {
        data.delete(name);
        continue;
      }
      if (
        !Number.isFinite(Number(value)) ||
        Number(value) <= 0 ||
        (name.endsWith("Id") && !Number.isInteger(Number(value)))
      )
        errors[name] = "Nhập số dương hợp lệ.";
    }
    for (const name of ["floorCount", "bedroomCount", "bathroomCount"]) {
      const value = String(data.get(name) || "");
      if (!value) {
        data.delete(name);
        continue;
      }
      if (!Number.isInteger(Number(value)) || Number(value) < 0)
        errors[name] = "Nhập số nguyên từ 0 trở lên.";
    }
    const files = Array.from(
      event.currentTarget.querySelector<HTMLInputElement>('input[name="files"]')
        ?.files || [],
    ).filter((file) => file.size > 0);
    if (files.length > 5) errors.files = "Chỉ chọn tối đa 5 ảnh.";
    if (files.some((file) => !["image/jpeg", "image/png"].includes(file.type)))
      errors.files = "Chỉ chọn ảnh JPG hoặc PNG.";
    data.delete("files");
    setFields(errors);
    setError("");
    if (Object.keys(errors).length) return;
    submitting.current = true;
    setLoading(true);
    try {
      for (const file of files) data.append("files", await resizePropertyImage(file));
      setSaved(await sellerApi.create(data));
    } catch (failure) {
      setError(
        failure instanceof TypeError
          ? "Lỗi kết nối. Hãy kiểm tra Tin đăng trước khi thử lại để tránh tạo trùng."
          : failure instanceof Error
            ? failure.message
            : "Lỗi kết nối. Kiểm tra Tin đăng trước khi thử lại.",
      );
      if (failure instanceof ApiError) setFields(failure.fields);
    } finally {
      submitting.current = false;
      setLoading(false);
    }
  }
  if (saved)
    return (
      <div role="status">
        <h1>Đã tiếp nhận tin #{saved.id}</h1>
        <p>
          {saved.status === "Chờ duyệt"
            ? receivedMessage
            : `Trạng thái từ hệ thống: ${statusLabel(saved.status)}`}
        </p>
        <Link className="button button-primary" to="/seller/properties">
          Xem bài đăng của tôi
        </Link>
      </div>
    );
  function field(name: string, label: string, type = "text", required = false) {
    return (
      <label key={name}>
        {label}
        {required && " *"}
        <input
          name={name}
          type={type}
          required={required}
          min={
            type === "number"
              ? name.endsWith("Count")
                ? "0"
                : "0.01"
              : undefined
          }
          step={name.endsWith("Count") ? "1" : "any"}
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
        {label}
        {!optional && " *"}
        <select
          name={name}
          required={!optional}
          defaultValue=""
          aria-invalid={!!fields[name]}
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
        <small role={fields[name] ? "alert" : undefined}>{fields[name]}</small>
      </label>
    );
  }
  return (
    <div>
      <div className="seller-header">
        <h1>Đăng tin mới</h1>
      </div>
      {optionsLoading && <p role="status">Đang tải danh mục...</p>}
      {optionsError && (
        <div role="alert">
          {optionsError}
          <button onClick={loadOptions}>Tải lại danh mục</button>
        </div>
      )}
      <form className="property-form" onSubmit={submit}>
        <fieldset
          disabled={loading || optionsLoading || !options || !!optionsError}
          className="form-fields"
        >
          {field("title", "Tiêu đề", "text", true)}
          <label>
            Mô tả
            <textarea name="description" rows={6} />
          </label>
          {select("typeId", "Loại hình giao dịch", options?.types)}
          {select("categoryId", "Phân khúc bất động sản", options?.categories)}
          {field("price", "Giá (VNĐ)", "number", true)}
          {field("area", "Diện tích (m²)", "number", true)}
          {field("floorCount", "Số tầng", "number")}
          {field("bedroomCount", "Phòng ngủ", "number")}
          {field("bathroomCount", "Phòng tắm", "number")}
          {field("direction", "Hướng nhà")}
          {field("address", "Địa chỉ đầy đủ", "text", true)}
          {select("wardId", "Phường/xã", options?.wards, true)}
          <small>
            Nếu chưa chọn phường/xã, hệ thống sẽ xác định từ địa chỉ. Hãy chọn
            phường/xã khi địa chỉ chưa xác định được.
          </small>
          {field("legal", "Thông tin pháp lý", "text", true)}
          <label>
            Ảnh (tối đa 5 JPG/PNG)
            <input
              name="files"
              type="file"
              multiple
              accept="image/png,image/jpeg"
            />
              <small>Ảnh lớn sẽ được thu nhỏ tối đa 1.920 px mỗi cạnh, giữ nguyên tỷ lệ.</small>
            <small role={fields.files ? "alert" : undefined}>
              {fields.files}
            </small>
          </label>
          {error && <p role="alert">{error}</p>}
          <button className="button button-primary" type="submit">
            {loading ? "Đang gửi..." : "Gửi tin chờ duyệt"}
          </button>
        </fieldset>
      </form>
    </div>
  );
}
