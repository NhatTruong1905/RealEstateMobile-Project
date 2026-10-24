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

export const receivedMessage =
  "Hệ thống đã tiếp nhận bài đăng của bạn. Bài đăng đang chờ nhân viên xét duyệt và chưa được công khai. Thông báo sẽ được gửi tới email đăng ký.";
export function statusLabel(status?: string) {
  return (
    (
      {
        "Chờ duyệt": "Đang chờ duyệt",
        "Đang mở bán": "Đã được duyệt",
        "Từ chối": "Bị từ chối",
        "Đã xóa": "Đã xóa",
      } as Record<string, string>
    )[status || ""] || "Chưa rõ"
  );
}
export function formatDate(value?: string | number) {
  if (value === undefined || value === null) return "Chưa có ngày";
  const date = new Date(value);
  return Number.isNaN(date.getTime())
    ? "Chưa có ngày"
    : date.toLocaleString("vi-VN");
}
