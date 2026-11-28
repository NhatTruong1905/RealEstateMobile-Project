# Các dịch vụ cloud của dự án

Bảng này ghi lại dịch vụ bên thứ ba theo vai trò trong dự án và nơi mở dashboard khi cần cấu hình hoặc kiểm tra. Các mục tích hợp chatbot mô tả cấu hình của dự án, còn trạng thái kết nối production cần kiểm tra trên môi trường triển khai.

| Dịch vụ | Dự án dùng để làm gì | Trang quản lý và tài liệu |
| --- | --- | --- |
| **Cloudflare R2** | Spring Boot lưu ảnh bất động sản trong bucket R2 qua API tương thích S3. `R2_BUCKET` chỉ định bucket, còn `R2_PUBLIC_BASE_URL` là địa chỉ công khai dùng để tải ảnh. | [Cloudflare Dashboard](https://dash.cloudflare.com/) · [Tài liệu R2](https://developers.cloudflare.com/r2/) |
| **CloudAMQP (RabbitMQ)** | Spring Boot gửi sự kiện khi tin được duyệt, sửa hoặc gỡ. Worker AI nhận sự kiện rồi đồng bộ dữ liệu sang Qdrant. Cấu hình kết nối qua `RABBITMQ_URL` và kiểu hàng đợi qua `RABBITMQ_QUEUE_TYPE`. | [CloudAMQP Console](https://customer.cloudamqp.com/) · [Hướng dẫn lấy URL AMQPS](https://www.cloudamqp.com/docs/cloudamqp-intro/) |
| **Qdrant Cloud** | Lưu vector của tin bất động sản để chatbot tìm tin phù hợp với câu hỏi. Dùng `QDRANT_URL`, `QDRANT_API_KEY` và `QDRANT_COLLECTION`. Tên collection production đã chọn là `realestate_gemini_prod_v1`. | [Qdrant Cloud Console](https://cloud.qdrant.io/) · [Hướng dẫn tạo cluster và Database API key](https://qdrant.tech/documentation/cloud/getting-started/) |
| **Google Gemini API** | Tạo embedding cho tin và câu hỏi, trích xuất tiêu chí tìm kiếm và sinh câu trả lời. Model chat được chọn qua `GEMINI_LLM_MODEL`. | [Google AI Studio](https://aistudio.google.com/) · [Quản lý API keys](https://aistudio.google.com/api-keys) |
| **Resend** | Spring Boot gọi HTTPS API để gửi email từ `no-reply@nhtr.id.vn`, gồm OTP quên mật khẩu và thông báo tiếp nhận, phê duyệt hoặc từ chối tin đăng. Tên miền gửi được xác minh qua Cloudflare DNS. | [Resend Dashboard](https://resend.com/emails) · [Cấu hình Resend trong dự án](RESEND_EMAIL_SETUP.md) |
| **Railway** | Nơi triển khai Spring Boot và dịch vụ AI theo cấu hình production của ứng dụng mobile. Dashboard dùng để xem deployment, log và cấu hình biến môi trường. | [Railway Dashboard](https://railway.com/dashboard) |
| **Supabase** | PostgreSQL production theo README của dự án. Spring Boot lấy chuỗi kết nối từ `DATABASE_URL` khi chạy profile `prod`. | [Supabase Dashboard](https://supabase.com/dashboard) |

## Tra cứu trong repo

- [Cấu hình mẫu chatbot](../../real-estate-ai/.env.example) liệt kê tên biến cần điền cho Gemini, Qdrant và RabbitMQ.
- [Hướng dẫn chạy chatbot](../../real-estate-ai/docs/SETUP_CHATBOT.md) có trình tự kiểm tra kết nối và đồng bộ dữ liệu.
- [Cấu hình lưu trữ R2](../../real-estate-backend/src/main/java/com/ndnt/configs/StorageConfiguration.java) cho biết các biến backend cần để kết nối bucket và tạo URL ảnh.

Lưu API key, token và URL AMQPS trong biến môi trường riêng của dịch vụ chạy production hoặc trong `.env` local đã được Git bỏ qua.
