# Tải trước ảnh trên frontend web

Triển khai ngày 17/11/2026. Chỉ áp dụng `real_estate_frontend-web`.

## Cấu trúc

| File | Trách nhiệm |
| --- | --- |
| `src/services/images/imagePrefetch.ts` | Hàng đợi tải ảnh nền, giới hạn và chống trùng |
| `src/services/images/propertyImages.ts` | Chọn URL ảnh thống nhất giữa thẻ và chi tiết |
| `src/components/property/PropertyImage.tsx` | Hiển thị ảnh và fallback có giới hạn |
| `src/components/property/PropertyGallery.tsx` | Album, chọn ảnh, thu gọn và tải trước ảnh kế tiếp |
| `src/hooks/usePropertyDetail.ts` | Lấy chi tiết và bỏ qua phản hồi của route cũ |
| `src/config/imageDelivery.ts` | Đọc origin ảnh để chuẩn bị kết nối |

## Hành vi

- Hai thẻ đầu tiên của mỗi danh sách tải ảnh eager; các thẻ còn lại dùng lazy loading của trình duyệt. Khung ảnh hiện có giữ nguyên kích thước.
- Pointer enter, focus hoặc touch trên thẻ gợi ý tải trước ảnh bìa. Vì hiện thẻ và chi tiết dùng cùng URL, trình duyệt có thể đã tải ảnh này; không tạo URL biến thể giả.
- Ảnh chính chi tiết tải eager, ưu tiên cao. Sau khi ảnh chính tải xong, lên lịch tối đa hai ảnh kế tiếp. Focus/hover thumbnail cũng có thể lên lịch ảnh tương ứng.
- Tối đa hai request nền hoạt động và tám URL chờ. URL đang chờ/đang tải được chống trùng; URL tải thành công được bỏ qua trong 60 giây. Chỉ giữ tối đa 48 bản ghi URL, không giữ thêm ảnh giải mã trong bộ nhớ JS.
- Lỗi tải nền không chặn điều hướng; cho phép thử lại ở lần tương tác tiếp theo. Request nền có timeout 15 giây.
- Bỏ qua prefetch khi offline, bật Save-Data hoặc kết nối 2G nếu trình duyệt cung cấp thông tin này. Việc tải ảnh để hiển thị vẫn hoạt động bình thường.
- Không thêm React Query. Không prefetch API: luồng khách hiện dùng danh sách tối đa 200 tin để tìm chi tiết; tránh gọi lặp endpoint này theo hover.

## Cấu hình phân phối ảnh

Trong file môi trường web, có thể đặt `VITE_IMAGE_ORIGIN` bằng origin custom domain ảnh R2 thực tế, ví dụ `https://images.example.com` (chỉ là minh họa). Khởi động lại Vite hoặc build lại sau khi đổi biến. Không cần đặt biến này để tải ảnh; nó chỉ bật `preconnect` sớm.

HTTP cache vẫn do trình duyệt và response header quyết định. Cửa sổ chống trùng 60 giây của service không phải TTL HTTP cache và không bảo đảm ảnh còn trong cache.

Chưa thay đổi Cloudflare, bucket, cache header, upload hoặc backend. API hiện chưa cung cấp URL thumbnail/medium riêng. Những phần này cần thực hiện tại pipeline ảnh và nơi phục vụ ảnh. Chỉ dùng cache dài hạn immutable khi URL thay đổi cùng nội dung; giữ nguyên cơ chế bảo vệ ảnh cần phân quyền.

## Kiểm tra

Chạy trong thư mục web:

```sh
npm run build
npm run lint
```

Kiểm thử hàng đợi dùng Node.js 22.18+ hoặc 24+ để chạy TypeScript trực tiếp, không cần thêm dependency.

Kiểm tra với DevTools Network trên môi trường có dữ liệu thật:

1. Đo cold cache với cùng thiết bị/mạng, rồi đo warm cache với Disable cache tắt.
2. Thử trang chủ, danh sách, tin đã lưu; hover/focus thẻ và mở chi tiết.
3. Chuyển thumbnail, thu gọn/mở rộng, dùng bàn phím và màn hình hẹp.
4. Kiểm tra URL ảnh prefetch trùng URL hiển thị, không có tải mạng lặp không cần thiết; phân biệt request từ memory/disk cache với tải mạng.
5. Kiểm tra `Cache-Control`, `Age`, `CF-Cache-Status`, dung lượng ảnh và thời gian ảnh chính xuất hiện.
6. Thử ảnh lỗi, fallback lỗi, offline/Save-Data và chuyển nhanh giữa hai tin.
7. Thay ảnh và xác minh URL/nội dung mới xuất hiện đúng.

Chưa có số đo trước/sau trên R2 thực tế hoặc xác minh trực quan bằng trình duyệt trong phiên triển khai này vì công cụ trình duyệt không khả dụng. Không cam kết mức cải thiện cho đến khi hoàn thành phép đo trên.

Tham khảo: [React preconnect](https://react.dev/reference/react-dom/preconnect), [MDN fetchPriority](https://developer.mozilla.org/en-US/docs/Web/API/HTMLImageElement/fetchPriority).
