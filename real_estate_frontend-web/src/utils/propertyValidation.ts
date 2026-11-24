import type { PropertyOptions } from "../services/api/seller/sellerApi";

export function validatePropertyFormData(data: FormData, options: PropertyOptions, invalidNumbers: ReadonlySet<string> = new Set()) {
  const errors: Record<string, string> = {};
  const selections = [
    ["typeId", "loại hình giao dịch", options.types, false],
    ["categoryId", "phân khúc bất động sản", options.categories, false],
    ["wardId", "phường/xã", options.wards, true],
  ] as const;
  for (const [name, label, items, optional] of selections) {
    const value = String(data.get(name) || "").trim();
    if (!value) {
      if (optional) data.delete(name);
      else errors[name] = `Vui lòng chọn ${label}.`;
    } else if (!items.some((item) => String(item.id) === value)) {
      errors[name] = `Lựa chọn ${label} không hợp lệ. Vui lòng chọn lại.`;
    }
  }
  for (const [name, label, max, required] of [
    ["title", "tiêu đề tin đăng", 255, true],
    ["address", "địa chỉ đầy đủ", 255, true],
    ["legal", "thông tin pháp lý", 45, true],
    ["direction", "hướng nhà", 45, false],
    ["city", "tỉnh/thành phố", 45, false],
  ] as const) {
    if (name === "city" && !data.has(name)) continue;
    const value = String(data.get(name) || "").trim();
    data.set(name, value);
    if (required && !value) errors[name] = `Vui lòng nhập ${label}.`;
    else if (value.length > max) errors[name] = `${label[0].toUpperCase()}${label.slice(1)} không được vượt quá ${max} ký tự.`;
  }
  for (const [name, label, max] of [
    ["price", "Giá bất động sản", 9999999999999.99],
    ["area", "Diện tích", 99999999.99],
  ] as const) {
    const raw = String(data.get(name) || "").trim();
    const value = Number(raw);
    const [mantissa, exponent = "0"] = raw.toLowerCase().split("e");
    const decimals = Math.max(0, (mantissa.split(".")[1]?.length || 0) - Number(exponent));
    if (invalidNumbers.has(name)) errors[name] = `${label} phải là số hợp lệ.`;
    else if (!raw) errors[name] = `Vui lòng nhập ${name === "price" ? "giá bất động sản" : "diện tích"}.`;
    else if (!/^[+-]?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?$/i.test(raw) || !Number.isFinite(value)) errors[name] = `${label} phải là số hợp lệ.`;
    else if (value <= 0) errors[name] = `${label} phải lớn hơn 0.`;
    else if (value > max) errors[name] = `${label} không được vượt quá ${max.toLocaleString("vi-VN", { maximumFractionDigits: 2 })}.`;
    else if (decimals > 2) errors[name] = `${label} chỉ được có tối đa 2 chữ số sau dấu thập phân.`;
  }
  for (const [name, label] of [
    ["floorCount", "Số tầng"], ["bedroomCount", "Số phòng ngủ"], ["bathroomCount", "Số phòng tắm"],
  ] as const) {
    const raw = String(data.get(name) || "").trim();
    const value = Number(raw);
    if (invalidNumbers.has(name)) errors[name] = `${label} phải là số nguyên hợp lệ.`;
    else if (!raw) data.delete(name);
    else if (!/^[+-]?\d+$/.test(raw) || !Number.isFinite(value)) errors[name] = `${label} phải là số nguyên hợp lệ.`;
    else if (value < 0) errors[name] = `${label} không được nhỏ hơn 0.`;
    else if (!Number.isInteger(value)) errors[name] = `${label} phải là số nguyên.`;
    else if (value > 2147483647) errors[name] = `${label} không được vượt quá 2.147.483.647.`;
    else data.set(name, String(value));
  }
  return errors;
}
