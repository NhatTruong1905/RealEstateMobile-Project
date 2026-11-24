# Email Nhà Thật qua Resend

Spring Boot gửi mã OTP đặt lại mật khẩu và thông báo tiếp nhận, duyệt, từ chối tin qua HTTPS `POST /emails`. Địa chỉ gửi mặc định là `Nhà Thật <no-reply@nhtr.id.vn>`. Tên miền `nhtr.id.vn` phải ở trạng thái **Verified** cho Sending trong Resend.

## Cấu hình backend

Đặt các biến trong **Railway → service Spring Boot → Variables**. Khi chạy cục bộ, đặt các biến môi trường tương ứng trước khi khởi động.

| Biến | Giá trị |
|---|---|
| `RESEND_API_KEY` | Dán key trong môi trường backend. Lưu dưới dạng secret. |
| `RESEND_FROM` | Tùy chọn. Mặc định `Nhà Thật <no-reply@nhtr.id.vn>`. |
| `PROPERTY_MAIL_MODE` | `resend`, hoặc bỏ biến để dùng mặc định. |
| `PROPERTY_MAIL_WORKER_ENABLED` | `true` khi muốn gửi mail tiếp nhận, duyệt và từ chối tin. Worker sẽ xử lý các bản ghi `PENDING` đến hạn, gồm cả bản ghi tồn từ trước. OTP gửi trực tiếp qua Resend và dùng chung API key. |

Xóa các biến cấu hình SMTP cũ ở service Spring Boot nếu còn. Nếu dùng thông báo tin, áp dụng migration outbox phù hợp trong [thư mục migrations](../real-estate-backend/db/migrations). Sau khi triển khai, thử đặt lại mật khẩu với tài khoản kiểm thử và xem **Resend → Emails**. Kiểm tra thông báo tin với một tin thử trên môi trường staging.

Backend chỉ trả `OTP_SENT` sau khi Resend chấp nhận yêu cầu. Trạng thái này xác nhận Resend đã nhận thư để xử lý. Khi Resend lỗi, backend trả HTTP 503 để ứng dụng hiện thông báo thử lại. OTP chỉ gửi đến email đã có trong tài khoản. Tài khoản chưa có email khôi phục sẽ nhận hướng dẫn liên hệ hỗ trợ.

HTML của email OTP và thông báo tin dùng chung [template Nhà Thật](../real-estate-backend/src/main/resources/templates/email/notification.html). Tiêu đề và nội dung tóm tắt của thông báo tin được đặt trong [PropertyMailOutbox.java](../real-estate-backend/src/main/java/com/ndnt/services/property/PropertyMailOutbox.java). Outbox lưu nội dung tại thời điểm tạo sự kiện, nên mẫu mới áp dụng cho sự kiện tạo sau khi backend chạy bản mới.

Backend chỉ cần quyền **Sending access**. Có thể giữ key **Full access** riêng để quản lý hoặc đọc thư inbound nếu cần dùng API. Bật nhận thư trong Resend là thao tác cấu hình domain và DNS. [Quyền API key](https://resend.com/changelog/new-api-key-permissions)

## Nhận thư với Cloudflare DNS

DNS công khai của `nhtr.id.vn` hiện có MX của P.A. Resend gửi thư qua cấu hình Sending đã xác minh. Phần nhận có hai cách tùy địa chỉ bạn muốn dùng:

- **Giữ email P.A và thử nhận trên Resend**. Thêm `inbox.nhtr.id.vn` trong Resend với **Receiving**. Sao chép đúng MX mà Resend hiển thị vào Cloudflare DNS cho subdomain đó, rồi bấm **I've added the record**. Sau khi verified, thử gửi đến `lienhe@inbox.nhtr.id.vn` và kiểm tra thư inbound trong Resend.
- **Nhận trực tiếp tại `lienhe@nhtr.id.vn` bằng Resend**. Trong **Resend → Domains → nhtr.id.vn → Enable Receiving**, lấy bản ghi MX được cấp. Chuyển MX tên miền gốc sang Resend sau khi đã xác nhận các hộp thư P.A có thể ngừng nhận thư mới. Việc chuyển MX có hiệu lực với toàn bộ địa chỉ `@nhtr.id.vn`.

[Hướng dẫn nhận trên domain riêng của Resend](https://resend.com/docs/dashboard/receiving/custom-domains) · [Hướng dẫn gửi qua API](https://resend.com/docs/api-reference/emails/send-email)
