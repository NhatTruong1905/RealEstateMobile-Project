# Chạy thử chatbot AI với dữ liệu bất động sản

Rà soát ngày 21/11/2026. Mục tiêu của lần chạy đầu là hỏi chatbot về một tin đã duyệt trên môi trường dev, rồi kiểm tra tin được cập nhật hoặc gỡ đúng khi backend thay đổi.

## Chatbot hoạt động thế nào

- Web và Flutter gửi câu hỏi đến FastAPI. Chatbot tìm tin phù hợp trong Qdrant, đối chiếu với Spring Boot để lấy dữ liệu hiện tại rồi dùng Gemini sinh câu trả lời.
- Lần đầu, lệnh `sync-backend` đưa dữ liệu từ Spring Boot vào Qdrant. Các lần duyệt, sửa và gỡ tin tiếp theo đi qua outbox của backend, RabbitMQ và worker Python.
- API và worker dùng chung thư mục `vector_database/` trong Compose. Thư mục này chứa manifest embedding và state SQLite dùng cùng collection Qdrant.

## Chuẩn bị

| Việc | Cần làm |
| --- | --- |
| Gemini | Điền `GEMINI_LLM_MODEL` bằng model ID mà project chứa `GOOGLE_API_KEY` truy cập được. Model cần hỗ trợ streaming và structured output. Xác nhận quota cho cả chat và embedding. |
| Qdrant Cloud | Điền `QDRANT_URL` và `QDRANT_API_KEY` bằng endpoint và Database API key có quyền đọc/ghi. Dùng collection dev riêng theo `QDRANT_COLLECTION`. |
| RabbitMQ Cloud | Điền `RABBITMQ_URL` bằng URL AMQPS. Chuẩn bị vhost dev và quyền configure/write/read. Xác nhận gói hỗ trợ quorum queues nếu giữ `RABBITMQ_QUEUE_TYPE=quorum`. |
| Spring Boot và DB dev | Chuẩn bị DB có vài tin đã duyệt. Áp dụng migration `004_property_index_mysql_forward.sql` hoặc `004_property_index_postgresql_forward.sql` trong `real-estate-backend/db/migrations/` theo DB đang dùng. Nếu DB đã áp dụng migration, kiểm tra cột `property.index_version` và bảng `property_index_outbox`. |
| Môi trường chạy AI | Mở Docker Desktop và chạy `docker version` để xác nhận phần Server hoạt động. Có thể dùng Python trong WSL nếu bạn đã thiết lập kết nối từ WSL tới backend. |

Bốn biến Gemini model, Qdrant URL/key và RabbitMQ URL ở trên vẫn là placeholder trong `real-estate-ai/.env` tại lúc rà soát. Giữ file hiện có và sửa từng biến. Kiểm tra `PROPERTY_API_TOKEN` khớp giữa AI và backend. Giữ `PROPERTY_INDEX_ENABLED=false` đến khi kiểm tra broker thành công và `RERANK_ENABLED=false` trong lần chạy đầu.

## Chạy trên Windows bằng Docker Desktop

1. Từ `real-estate-backend/`, khởi động Spring Boot bằng cấu hình Maven hoặc IDE đang dùng. Thêm profile `chatbot-index` vào các profile hiện có. Với thư mục chạy này, profile đọc `../real-estate-ai/.env`. Compose gọi backend qua `http://host.docker.internal:8080/api/internal/ai`. Nếu cổng hoặc context path khác, điền `PROPERTY_API_CONTAINER_URL` trong `.env`.
2. Từ `real-estate-ai/`, build image và kiểm tra cấu hình. Lệnh broker kết nối đến vhost dev và khai báo exchange, queue và binding.

   ```powershell
   docker compose --profile app build worker api
   docker compose --profile app run --rm worker python -m rag.dev setup-check
   docker compose --profile app run --rm worker python -m rag.broker check
   ```

   Lần chạy đầu, `setup-check` báo `needs_setup` và trả mã 1 nếu chưa có `embedding_smoke` hoặc `parent_state`. Nếu chỉ hai mục này còn thiếu, tiếp tục kiểm tra broker và tạo chúng ở bước 3.

3. Khi migration và broker đã sẵn sàng, đặt `PROPERTY_INDEX_ENABLED=true` và khởi động lại Spring Boot. Kiểm tra Gemini và đồng bộ một trang nhỏ. Các lệnh có `--allow-api-calls` có thể dùng quota hoặc phát sinh phí.

   ```powershell
   docker compose --profile app run --rm worker python -m rag.dev gemini-smoke --allow-api-calls
   docker compose --profile app run --rm worker python -m rag.dev sync-backend --allow-api-calls --limit 20 --after 0
   ```

4. Lặp `sync-backend` với giá trị `next_after` trả về cho đến khi hết dữ liệu. Nếu `failed > 0`, sửa lỗi rồi tiếp tục từ cursor được trả về để xử lý lại tin lỗi. Kiểm tra Qdrant và khởi động API cùng worker.

   ```powershell
   docker compose --profile app run --rm worker python -m rag.dev qdrant-check
   docker compose --profile app up -d worker api
   docker compose --profile app logs --tail 80 worker api
   ```

## Kiểm tra kết quả

1. Mở Swagger tại `http://127.0.0.1:8000/docs`. Gọi `POST /api/chat-rag` và `POST /api/chat-rag/stream` với JSON có trường `question`. Hỏi về khu vực hoặc mức giá của một tin đã đưa vào index. Kiểm tra câu trả lời có thông tin khớp với tin. Endpoint stream truyền từng phần văn bản.
2. Duyệt một tin thử trong admin. Kiểm tra outbox chuyển sang `SENT`, worker xử lý thành công và chatbot tìm được tin. Sửa một chi tiết có thể đối chiếu rồi hỏi lại. Gỡ tin, thử bằng cuộc hội thoại mới và kiểm tra chatbot đã loại tin khỏi kết quả.
3. Khi API đạt, thử từ web với `VITE_AI_BASE_URL=http://localhost:8000/api`. Chạy Vite trên cổng `5173` để khớp cấu hình CORS hiện tại. Flutter debug trên Android Emulator dùng `http://10.0.2.2:8000/api`. Hướng dẫn này dùng trình duyệt trên máy chạy Docker hoặc Android Emulator vì Compose publish cổng AI trên loopback.

| Dấu hiệu | Kiểm tra trước |
| --- | --- |
| Docker báo thiếu named pipe Linux Engine | Mở Docker Desktop, đợi Engine sẵn sàng rồi chạy lại `docker version`. |
| Property API trả 401 | Kiểm tra token hai phía và profile `chatbot-index` đã được nạp. |
| Container không kết nối được backend | Kiểm tra backend đang chạy, cổng, context path và `PROPERTY_API_CONTAINER_URL`. |
| Broker báo lỗi khai báo queue | Kiểm tra vhost, quyền và queue type của broker dev. |
| API chạy nhưng chưa tìm thấy tin | Kiểm tra tin đã duyệt, kết quả `sync-backend`, collection/state đang dùng và log worker. Outbox `SENT` chỉ xác nhận publisher đã gửi sự kiện. |

## Bật rerank sau khi luồng cơ bản chạy

Qwen3-Reranker-0.6B qua vLLM là bước tiếp theo sau khi kiểm tra luồng chat và đồng bộ. Khi đó mới cần xử lý dung lượng tại nơi Docker lưu image, driver GPU và kiểm tra `rerank-check` trước khi bật `RERANK_ENABLED=true`.

Xem [hướng dẫn đầy đủ](SETUP_FULL_STACK.md) để tra cấu hình cloud, quyền broker, vLLM và vận hành. Xem [trạng thái triển khai](IMPLEMENTATION_STATUS.md) để biết các lần kiểm thử trước và các hạng mục còn cần nghiệm thu với dịch vụ thật.
