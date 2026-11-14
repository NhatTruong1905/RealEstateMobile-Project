# Bắt đầu với chatbot AI

Cập nhật 14/11/2026. Hướng dẫn thao tác đầy đủ: [SETUP_FULL_STACK.md](SETUP_FULL_STACK.md). Các kết quả đã kiểm chứng và phần còn thiếu: [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md).

## Cấu hình đã chọn

| Thành phần | Hiện tại |
|---|---|
| LLM / embedding | Gemini API, key nằm trong `.env` của service |
| Vector DB | Qdrant Cloud, Database API key của cluster |
| Đồng bộ property | RabbitMQ Cloud qua AMQPS, backend outbox → AI worker |
| Rerank dev | Qwen3-Reranker-0.6B qua vLLM local |
| Rerank production | Sẽ chuyển sang provider API sau khi xác minh contract; chưa đổi hiện tại |

Cài dependency từ duy nhất `requirements.txt`, chạy trong `real-estate-ai/`:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Giữ `.env` đang có, đối chiếu `.env.example` và bổ sung URL/key theo [mục 2](SETUP_FULL_STACK.md#2-điền-env-lấy-ở-đâu). Không copy đè key cũ, không gửi key qua chat. `scripts/`, `tests/`, `postman/` đã được gỡ; không còn bước chạy script tải model hoặc pytest trong quy trình setup hiện tại.

## Trình tự thực hiện

1. Điền Gemini model/key, Qdrant Cloud URL/Database API key và RabbitMQ Cloud AMQPS URL. Broker không chạy trong Docker.
2. Áp dụng migration backend theo DB thực tế, cấu hình `PROPERTY_API_TOKEN` chung và profile `chatbot-index` theo mục 3 hướng dẫn chính.
3. Kiểm tra broker bằng `python -m rag.broker check`; lệnh kết nối thật và khai báo topology. Bật outbox publisher khi broker/migration sẵn sàng.
4. Chạy `setup-check`, Gemini smoke và `sync-backend` batch nhỏ theo mục 6. Smoke/sync gọi Gemini có thể tính phí; kiểm tra ngân sách trước khi dùng flag `--allow-api-calls`.
5. Khởi động worker để nhận duyệt/sửa/gỡ property. Tiếp tục snapshot bằng `next_after`, không tăng cursor vượt lỗi.
6. Xử lý driver/dung lượng Docker, khởi động vLLM local và chạy `rerank-check` trước khi bật `RERANK_ENABLED=true`.
7. Khởi động API sau khi index/state sẵn sàng; kiểm tra chat/stream và tin bị gỡ với dữ liệu thật.

Windows đang có giới hạn native gRPC DLL tại lần kiểm thử trước: dùng Linux/WSL hoặc profile `app` của Compose theo hướng dẫn chính. Đây là tùy chọn chạy ứng dụng, không tạo broker RabbitMQ local. Không khởi động API để tự embed toàn bộ dữ liệu.

## Sau này dùng API rerank

Đổi `RERANK_BASE_URL`, `RERANK_MODEL`, `RERANK_API_KEY`; với Compose phải đổi thêm `RERANK_CONTAINER_BASE_URL`. Xác minh contract, smoke provider có kiểm soát quota rồi mới bật rerank và khởi động lại API. Quy trình và bảng dọn tài nguyên nằm ở [mục 7](SETUP_FULL_STACK.md#7-chuyển-production).

Template `deploy/qwen3_reranker.jinja`, model local và service vLLM có thể bỏ khi không cần local/rollback nữa. `deploy/property-event.schema.json` là contract RabbitMQ nên giữ hoặc chuyển nơi khác; chỉ bỏ cả thư mục `deploy/` sau khi cập nhật các tham chiếu tương ứng.
