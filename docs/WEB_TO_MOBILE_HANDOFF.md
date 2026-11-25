# Bàn giao nghiệp vụ web sang mobile

Agent làm web cập nhật tài liệu này sau mỗi lượt có chỉnh frontend. Agent làm Flutter đọc mục liên quan trước khi thực hiện nghiệp vụ tương ứng.

## Các mục bàn giao

| Nghiệp vụ | Tình trạng và tài liệu |
| --- | --- |
| Chatbot AI | Web đã chuyển sang SSE v2, hiển thị thẻ tin và hỗ trợ tham chiếu tin. Flutter còn chờ chuyển hợp đồng API. [Bàn giao chatbot cho Flutter](CHATBOT_MOBILE_HANDOFF.md) |
| Gửi lại tin bị từ chối | Đã triển khai backend và web. Flutter còn chờ tích hợp. Xem hợp đồng API bên dưới. |
| Chi tiết tin của tôi | Web mở chi tiết riêng cho chủ tin từ danh sách. Flutter còn chờ tích hợp. |

Danh sách **Tin đăng của tôi** từ `GET /api/secure/properties` trả tin theo thời gian chỉnh sửa mới nhất trước, cả khi có và không có phân trang. Tin chưa chỉnh sửa dùng ngày đăng. Nếu trùng thời điểm, ID lớn hơn đứng trước. API công khai `GET /api/properties` dùng cho trang chủ trả tin đã công khai theo ID giảm dần. Flutter có thể giữ thứ tự trả về từ hai API, kể cả khi ghép các trang.

## Liên hệ hỗ trợ

Cập nhật 25/11/2026. [Chân trang web](../real_estate_frontend-web/src/layouts/Footer.tsx) hiển thị **Hỗ trợ khách hàng** với email `support@nhtr.id.vn` và **Liên hệ hợp tác** với số `0967 294 349`. Hai liên kết mở ứng dụng email và gọi điện tương ứng. Không cần thay đổi API hay quyền truy cập. Khi cập nhật màn hình hỗ trợ trong Flutter, dùng địa chỉ này cho liên hệ hỗ trợ của Nhà Thật. Build và lint đã chạy thành công, hai liên kết đã được kiểm tra trên Edge headless với kích thước cửa sổ 390 và 1440 px.

Nút **Liên hệ qua email** trong mục **Vẫn cần hỗ trợ thêm?** trên [trang câu hỏi thường gặp](../real_estate_frontend-web/src/screens/support/SupportScreens.tsx) mở thư mới đến `support@nhtr.id.vn`. Khi triển khai nút tương ứng trên Flutter, dùng cùng địa chỉ.

## Chi tiết tin của tôi

Cập nhật 24/11/2026. Web mở `/seller/properties/{id}` khi chọn một tin trong **Tin đăng của tôi**. Trang hiển thị ảnh, loại giao dịch, phân khúc, địa chỉ, giá, diện tích, số phòng/tầng, hướng, pháp lý, mô tả, trạng thái và thời điểm xét duyệt. Tin bị từ chối có lý do và nút **Sửa và gửi lại**.

Flutter gọi `GET /api/secure/properties/{id}/mine` bằng JWT rồi đọc DTO trong `data`. API này chỉ trả dữ liệu cho chủ tin và trả 404 nếu tin thiếu hoặc thuộc người khác. Không dùng API chi tiết công khai cho màn hình quản lý. Tái sử dụng cách hiển thị chi tiết thông số và ảnh, thêm khối trạng thái và điều hướng quay lại danh sách tin cá nhân.

Khối trạng thái trên web dùng nhãn chữ và biểu tượng, với màu vàng cho chờ duyệt, xanh cho đã duyệt, đỏ cho từ chối và trung tính cho các trạng thái còn lại. Lý do từ chối nằm ngay trên nút **Sửa và gửi lại**. Flutter có thể áp dụng cùng thứ tự thông tin khi triển khai giao diện, hợp đồng API giữ nguyên.

Đã kiểm tra build/lint web, điều hướng và lý do từ chối trên Edge với API giả lập. Backend có kiểm thử chủ tin đọc được lý do và tài khoản khác nhận 404.

## Gửi lại tin bị từ chối

Cập nhật 24/11/2026. Ở **Tin đăng của tôi** trên web, chủ tin bị từ chối có thể mở **Sửa và gửi lại**, xem lý do, sửa nội dung và ảnh, rồi **Lưu chỉnh sửa**. Lưu giữ trạng thái **Từ chối**. Nút **Gửi lại để xét duyệt** thực hiện bước riêng để chuyển tin về **Chờ duyệt**.

Màn hình sửa điền sẵn thông tin gốc, gồm tiêu đề, giao dịch, phân khúc, giá, diện tích, địa chỉ, tỉnh/thành phố, phường/xã, pháp lý, hướng, số phòng/tầng, mô tả và ảnh. Có thể sửa từng trường, giữ hoặc xóa ảnh cũ và thêm ảnh mới. Trường multipart `city` là tỉnh/thành phố, tối đa 45 ký tự. Khi có giá trị, backend ưu tiên giá trị đã nhập nếu phải phân tích địa chỉ để tìm phường/xã. Khi Flutter triển khai, điền sẵn `city` từ DTO và gửi lại giá trị mới trong bản sửa.

Đã kiểm tra từ chi tiết sang màn sửa trên Edge với API giả lập, gồm điền sẵn mô tả, đổi tỉnh/thành, xem lại và lưu bản sửa. Kiểm thử backend kiểm tra DTO trả về tỉnh/thành mới trong khi trạng thái tin vẫn là `Từ chối`.

Màn xác nhận sau khi lưu tách mã tin và trạng thái khỏi tiêu đề, đặt **Gửi lại để xét duyệt** làm hành động chính và **Xem tin đăng của tôi** làm hành động phụ. Trên màn hẹp, hai nút xếp dọc. Đã kiểm tra bố cục trên Edge ở 1200 px và 390 px. Flutter có thể dùng cùng thứ tự hành động và trạng thái, không cần thay đổi API.

1. Đọc tin bằng `GET /api/secure/properties/{id}/mine`. Chỉ hiển thị thao tác sửa và gửi lại cho chủ tin đang có trạng thái `Từ chối`.
2. Lưu bản sửa bằng `POST /api/secure/properties?rejectedDraft=true`, multipart như API đăng tin hiện có, kèm `id`. Khi đổi ảnh, gửi danh sách URL ảnh muốn giữ qua `images` và ảnh mới qua `files`. Bỏ trường `images` để giữ toàn bộ ảnh cũ. Gửi `images` rỗng để bỏ toàn bộ ảnh cũ.
3. Gửi lại bằng `POST /api/secure/properties/{id}/resubmit`, không có body, dùng JWT của chủ tin. Phản hồi thành công trả DTO ở `data`, trạng thái `Chờ duyệt` và thông tin từ chối của vòng trước được xóa. Lấy trạng thái từ API và tải lại danh sách.
4. Xử lý 403 nếu không phải chủ tin và 409 nếu trạng thái đã đổi hoặc hộp thư xét duyệt chưa được cấu hình. Ngăn bấm lặp trong khi chờ phản hồi. Nếu lỗi mạng, đọc lại trạng thái trước khi gửi lại.

Backend đưa một sự kiện `RESUBMITTED` vào outbox mỗi lượt gửi lại, mặc định gửi tới `moderation@nhtr.id.vn`. Các lần xét duyệt dùng phiên bản hiện tại của tin trong khóa outbox để gửi được thông báo cho nhiều vòng. Worker Resend cần chạy để thực sự giao thư. Flutter không cần thay đổi API. [Cấu hình gửi email](RESEND_EMAIL_SETUP.md)

Form quản trị gửi `reviewVersion` khi xét duyệt để backend trả 409 nếu admin đang xem bản cũ. Flutter không cần gửi trường này trong luồng chủ tin.

Cập nhật 25/11/2026. Nút **Lưu bài đăng** trong trang quản trị đưa người dùng về `/admin/properties-list` khi lưu thành công. Khi lưu lỗi, form giữ nguyên dữ liệu và hiển thị thông báo. Thay đổi nằm ở [form quản trị](../real-estate-backend/src/main/resources/templates/property/edit.html) và [mã xử lý form](../real-estate-backend/src/main/resources/static/js/property-approval.js). Đã kiểm tra cú pháp JavaScript và hai nhánh thành công, lỗi 409 bằng phản hồi giả lập. Hợp đồng API giữ nguyên. Flutter không cần thay đổi.

Tệp đối chiếu web và backend gồm [màn hình sửa tin](../real_estate_frontend-web/src/screens/seller/PostPropertyScreen.tsx), [seller API](../real_estate_frontend-web/src/services/api/seller/sellerApi.ts) và [APIPropertyController](../real-estate-backend/src/main/java/com/ndnt/controllers/api/APIPropertyController.java).

Kiểm tra đã đạt gồm build/lint web, luồng lưu và gửi lại trên Edge với API giả lập, cùng kiểm thử backend cho quyền chủ tin, gửi lại trùng, phiên xét duyệt cũ và email từ chối vòng thứ hai. Kiểm thử xác nhận email được ghi vào outbox. Chưa gửi email thật cho admin trong lần kiểm tra này.

## Nội dung cho mỗi mục

- Ngày cập nhật, tên nghiệp vụ, màn hình hoặc luồng liên quan.
- Hành vi đã triển khai trên web, gồm quyền, trạng thái và các trường hợp lỗi có liên quan.
- API, dữ liệu hoặc tệp mã cần đối chiếu.
- Việc cần thực hiện ở Flutter và kết quả kiểm tra ở từng nền tảng.
