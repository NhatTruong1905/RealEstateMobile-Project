export function formatMoney(value?: number) {
  if (!value) return "Liên hệ";
  if (value >= 1_000_000_000) {
    return `${(value / 1_000_000_000).toLocaleString("vi-VN", {
      maximumFractionDigits: 1,
    })} tỷ`;
  }
  return `${(value / 1_000_000).toLocaleString("vi-VN", {
    maximumFractionDigits: 0,
  })} triệu`;
}
