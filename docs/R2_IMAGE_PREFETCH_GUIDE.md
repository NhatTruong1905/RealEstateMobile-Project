# Tải trước và cache ảnh từ Cloudflare R2

Ngày ghi nhận: 16/11/2026.

## 1. Mục tiêu và phạm vi

Giảm thời gian chờ ảnh khi xem danh sách, mở chi tiết và chuyển ảnh bất động sản. Tài liệu này giải thích cơ chế và hướng thực hiện; chưa triển khai thay đổi vào ứng dụng hoặc cấu hình Cloudflare.

Hiện trạng kiểm tra từ manifest của dự án:

- `real_estate_frontend-web`: React 19, Vite; chưa khai báo `@tanstack/react-query`.
- `real_estate_frontend-mobile`: Flutter; chưa khai báo thư viện cache ảnh xuống đĩa riêng.
- Cấu hình CDN/cache R2 thực tế cần kiểm tra khi triển khai, chưa thể kết luận từ manifest frontend.

## 2. Vì sao ảnh chậm? Có phải chỉ khi mới mở website?

Không chỉ lần đầu mở website. Ảnh thường phải đi qua các bước:

```text
Lấy dữ liệu API để biết URL ảnh
  → tra DNS và thiết lập kết nối nếu cần
  → tải file ảnh qua mạng
  → giải mã ảnh
  → hiển thị
```

Khi đã có cache còn dùng được, những lần xem tiếp theo thường nhanh hơn. Tuy nhiên, mở một căn nhà mới, cuộn đến ảnh chưa tải, cache hết hạn/bị loại bỏ hoặc URL thay đổi đều có thể khiến ảnh phải tải lại. Reload cũng không mặc định xóa cache ảnh.

Hai nơi cache cần phân biệt:

| Nơi lưu | Lợi ích | Giới hạn |
| --- | --- | --- |
| Trình duyệt hoặc thiết bị | Dùng lại ảnh đã tải; có thể tránh tải mạng | Có thể bị xóa hoặc loại bỏ; bộ nhớ và dung lượng có giới hạn |
| CDN Cloudflare | Phục vụ ảnh từ máy chủ biên thay vì truy xuất R2 mỗi lần | Thiết bị vẫn cần nhận ảnh qua mạng nếu chưa có cache cục bộ |

Prefetch chuyển việc tải sang thời điểm sớm hơn. Chỉ khi tải xong và cache còn tồn tại thì màn hình tiếp theo mới có thể hưởng lợi đầy đủ; không bảo đảm mọi ảnh xuất hiện tức thì.

## 3. React Query, prefetchDNS và image prefetch

| Cơ chế | Công việc | Có tải file ảnh không? |
| --- | --- | --- |
| React Query `prefetchQuery` | Chạy query và lưu kết quả, thường là JSON có URL ảnh | Không, nếu query chỉ lấy JSON |
| React DOM `prefetchDNS` | Gợi ý trình duyệt tra IP của tên miền ảnh | Không |
| React DOM `preconnect` | Gợi ý chuẩn bị kết nối tới tên miền ảnh | Không |
| Image prefetch | Bắt đầu tải file ảnh trước lúc hiển thị | Có, nếu request thành công |

React Query không tự đọc URL trong JSON rồi tải ảnh. `staleTime` điều khiển độ mới của dữ liệu query, không phải thời hạn cache file ảnh. Cache React Query mặc định cũng không đồng nghĩa dữ liệu được lưu bền qua reload.

DNS prefetch chỉ giảm một phần thời gian chuẩn bị kết nối. Nó không khắc phục ảnh nhiều MB, CDN chưa cache hoặc thời gian giải mã ảnh lớn. Với một tên miền ảnh chắc chắn sẽ dùng, cân nhắc `preconnect`; không cần thêm cả hai một cách máy móc cho cùng origin.

## 4. Thứ tự triển khai đề xuất

### Bước 1: Đo trước khi sửa

Trên web, dùng DevTools > Network và xem request ảnh:

- Kích thước truyền, thời gian chờ phản hồi và thời gian tải nội dung.
- Header `Cache-Control`, `Age`, `CF-Cache-Status` nếu có.
- Ảnh được đọc từ memory/disk cache hay thực sự tải mạng.
- API lấy URL có làm ảnh bắt đầu tải quá muộn không.

Đo riêng cache lạnh và cache ấm với cùng điều kiện mạng. Khi đo lần xem lại, tắt tùy chọn Disable cache. Thử cả mở trực tiếp trang chi tiết và điều hướng từ danh sách.

### Bước 2: Tối ưu file ảnh và đường phân phối

- Tạo thumbnail cho danh sách, ảnh vừa cho chi tiết và ảnh lớn cho chế độ xem đầy đủ.
- Chọn kích thước theo vùng hiển thị và mật độ điểm ảnh; tránh dùng ảnh gốc nhiều MB cho thẻ nhỏ.
- Cân nhắc WebP/AVIF sau khi kiểm tra hỗ trợ trên nền tảng mục tiêu.
- Với ảnh công khai, gắn custom domain vào bucket R2 và kiểm tra chính sách CDN cache. `r2.dev` dành cho phát triển, không phải đường phục vụ production.
- R2 lưu trữ object; việc tạo các biến thể ảnh cần pipeline upload/xử lý ảnh hoặc dịch vụ biến đổi ảnh riêng.

Ví dụ chỉ dành cho ảnh công khai, có tên file thay đổi theo nội dung:

```http
Cache-Control: public, max-age=31536000, immutable
```

Ví dụ URL: `/properties/123/cover-a1b2c3.webp`. Khi thay ảnh, đổi URL rồi cập nhật dữ liệu API. Không dùng cache dài hạn như trên nếu vẫn ghi đè nội dung vào cùng URL và cần cập nhật ngay. Header cache phía client và chính sách cache CDN cần được kiểm tra riêng.

Nếu ảnh dùng URL ký có thời hạn hoặc cần phân quyền, giữ cơ chế bảo vệ; không tự chuyển sang public cache. URL ký thay đổi cũng có thể làm giảm khả năng tái sử dụng cache, tùy cache key.

### Bước 3: Tải trước có chọn lọc

```text
Hiển thị danh sách
  → tải ảnh đang nhìn thấy trước
  → khi có ý định mở một căn: lấy trước JSON và ảnh bìa
  → mở chi tiết: dùng cache nếu còn
  → tải thêm 1–2 ảnh kế tiếp trong album
```

Giới hạn ban đầu có thể là 2–4 request ảnh nền đồng thời, sau đó điều chỉnh theo đo đạc. Không tải toàn bộ album hoặc toàn bộ danh sách: dễ tranh băng thông với ảnh đang cần và tăng bộ nhớ. Tránh lặp lại prefetch mỗi lần component render; cho phép thử lại khi lần tải trước thất bại.

## 5. Cách thực hiện trên React web

### Chuẩn bị kết nối

Ví dụ trong component gốc, thay origin bằng domain ảnh thật:

```tsx
import { preconnect } from 'react-dom';

function App() {
  preconnect('https://images.example.com');
  return <AppRoutes />;
}
```

`AppRoutes` là thành phần minh họa. Nếu chỉ muốn tra DNS cho một domain có thể sẽ dùng, dùng `prefetchDNS` từ `react-dom`. Đây là gợi ý; trình duyệt quyết định thực hiện.

### Tải trước dữ liệu và ảnh

Nếu quyết định dùng React Query, cài `@tanstack/react-query`, tạo một `QueryClient` ổn định và bọc ứng dụng bằng `QueryClientProvider`. Mẫu dưới đây dùng API v5; `getProperty`, `queryClient`, dữ liệu `property` và phần điều hướng cần nối với code thực tế.

```tsx
const propertyOptions = (id: string) => ({
  queryKey: ['property', id],
  queryFn: () => getProperty(id),
  staleTime: 60_000,
});

function warmProperty(id: string, coverUrl: string) {
  // Hai công việc bắt đầu độc lập vì danh sách đã có URL ảnh bìa.
  void queryClient.prefetchQuery(propertyOptions(id));

  const image = new Image();
  image.src = coverUrl;
}

// Trên liên kết/thẻ nhà:
// onMouseEnter={() => warmProperty(property.id, property.coverUrl)}
// onFocus={() => warmProperty(property.id, property.coverUrl)}

// Trong trang chi tiết, dùng cùng query key và chính sách staleTime:
const { data } = useQuery(propertyOptions(id));
```

Hover/focus là tín hiệu phù hợp trên desktop và bàn phím. Với màn hình cảm ứng, cân nhắc tải một số ảnh gần vùng nhìn thấy; thao tác chạm sát lúc điều hướng có thể không đủ thời gian tải trước.

Ví dụ dùng `new Image()` để trình duyệt bắt đầu tải ảnh; thời gian giữ ảnh phụ thuộc HTTP cache và tài nguyên thiết bị. URL prefetch cần khớp ảnh thực tế sẽ dùng. Nếu danh sách dùng thumbnail còn chi tiết dùng ảnh lớn, tải thumbnail không có nghĩa ảnh lớn đã được cache. Khi dùng `srcSet`, cần chọn đúng biến thể và tránh tải dư.

Không cần cài React Query chỉ để tải trước ảnh. Có thể triển khai image prefetch với cơ chế lấy dữ liệu hiện tại, rồi đánh giá riêng nhu cầu cache dữ liệu API.

### Hiển thị ảnh

- Giữ sẵn tỷ lệ hoặc kích thước khung ảnh để tránh nhảy bố cục.
- Có placeholder và trạng thái lỗi/thử lại.
- Ảnh chính ở vùng đầu màn hình cần tải sớm; không lazy-load máy móc mọi ảnh.
- Ảnh ngoài vùng nhìn thấy có thể dùng lazy loading.
- Không chờ toàn bộ prefetch hoàn tất mới cho điều hướng hoặc hiển thị nội dung.

## 6. Cách thực hiện trên Flutter mobile

React Query và `react-dom/prefetchDNS` không áp dụng trực tiếp cho Flutter. Dùng cơ chế image cache của Flutter, ví dụ:

```dart
Future<void> warmCover(BuildContext context, String url) async {
  await precacheImage(
    NetworkImage(url),
    context,
    onError: (error, stackTrace) {
      // Ghi nhận lỗi nếu cần; không chặn người dùng mở chi tiết.
    },
  );
}

// Hiển thị với cùng URL/provider key:
// Image(image: NetworkImage(url), fit: BoxFit.cover)
```

Gọi khi có URL và context còn hợp lệ, chẳng hạn lúc chuẩn bị nội dung sắp được xem; không gọi lặp lại vô điều kiện trong `build`. Với nhiều ảnh, giới hạn số lượng và kiểm tra vòng đời widget trước các lần gọi tiếp theo.

`precacheImage` chuẩn bị ảnh trong image cache của Flutter; không bảo đảm ảnh được giữ mãi và không tự cung cấp cache đĩa bền qua lần khởi động app. Future hoàn tất cũng không khẳng định tải thành công: dùng `onError` để ghi nhận thất bại. Nếu cần cache đĩa, đánh giá thư viện phù hợp và dùng cùng cơ chế cache cho cả tải trước lẫn hiển thị.

## 7. Kiểm tra sau triển khai

- Đo thời gian ảnh chính xuất hiện trước/sau trên cùng thiết bị và mạng.
- Thử lần đầu, quay lại trang cũ, mở căn mới và reload.
- Kiểm tra request prefetch có được dùng lại, có tải trùng hoặc tải sai biến thể không.
- Kiểm tra ảnh mới xuất hiện đúng sau khi cập nhật nội dung.
- Thử mạng chậm, ảnh lỗi và URL hết hạn; nội dung vẫn điều hướng được.
- Theo dõi băng thông và bộ nhớ khi cuộn nhiều hoặc mở album dài.

Chấp nhận thay đổi khi thời gian chờ ảnh giảm trong kịch bản mục tiêu và lượng tải nền không làm chậm ảnh đang hiển thị. Chưa đặt con số cam kết trước khi có baseline.

## 8. Tài liệu tham khảo

- [TanStack Query: Prefetching](https://tanstack.com/query/latest/docs/framework/react/guides/prefetching)
- [React: prefetchDNS](https://react.dev/reference/react-dom/prefetchDNS)
- [React: preconnect](https://react.dev/reference/react-dom/preconnect)
- [Cloudflare R2: Public buckets và custom domain](https://developers.cloudflare.com/r2/buckets/public-buckets/)
- [Flutter: precacheImage](https://api.flutter.dev/flutter/widgets/precacheImage.html)
