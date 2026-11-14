# Kế hoạch chatbot AI: dev local và chuyển sang API production

Cập nhật 14/11/2026. Tài liệu này thay các chỉ dẫn dev trước đây về mock-only, Qdrant local và chưa tích hợp messaging. Hướng dẫn thao tác chính: [SETUP_FULL_STACK.md](../real-estate-ai/docs/SETUP_FULL_STACK.md). Bằng chứng đã chạy và giới hạn: [IMPLEMENTATION_STATUS.md](../real-estate-ai/docs/IMPLEMENTATION_STATUS.md).

## 1. Các quyết định hiện tại

| Thành phần | Dev hiện tại | Khi lên production |
|---|---|---|
| LLM | Gemini API | Dùng key production; đổi provider cần adapter tương ứng |
| Embedding | Gemini embedding API | Key riêng nếu cần; đổi embedding contract phải re-index |
| Vector database | Qdrant Cloud | Cluster/collection/state production riêng |
| Rerank | Qwen3-Reranker-0.6B qua vLLM local | Chuyển sang API rerank sau khi xác minh contract |
| Messaging | RabbitMQ Cloud qua AMQPS | Broker/vhost/quyền truy cập production |
| Cài dependency | Một file `real-estate-ai/requirements.txt` | Dùng cùng đầu vào dependency của service |

Model 4B không còn là lựa chọn. Broker RabbitMQ không chạy trong Docker. `scripts/`, `tests/`, `postman/` của service AI đã được gỡ khỏi repo; không dùng lệnh tải model từ script cũ hoặc pytest như bước setup hiện tại. Test Java backend là phạm vi khác.

## 2. Luồng đã có trong mã

```text
Duyệt / sửa / gỡ property
  → DB property + indexing outbox cùng transaction
  → publisher confirms + mandatory/returns
  → RabbitMQ Cloud
  → AI worker hydrate trạng thái hiện tại từ backend
  → normalize / chunk / embedding phần đổi
  → Qdrant Cloud + SQLite parent/version state
  → ACK sau khi ghi hoàn tất
```

Luồng chat: Gemini trích xuất nhu cầu → embedding truy vấn → Qdrant → hydrate nguồn chuẩn/lọc → rerank HTTP → context → Gemini trả lời/stream. Lỗi rerank dùng thứ tự candidates đã lọc; không coi fallback là model inference thành công. Stream hiện là text streaming, chưa phải structured SSE.

Worker có retry TTL, DLQ, redrive, version/tombstone và snapshot/reconcile. Không có exactly-once end-to-end; Qdrant ghi thành công trước crash/ACK có thể được xử lý lại. Queue thông thường không giữ lịch sử sau ACK; rebuild từ nguồn chuẩn.

## 3. Rerank local hiện tại

- Model: `Qwen/Qwen3-Reranker-0.6B`, lưu ở `real-estate-ai/models/Qwen3-Reranker-0.6B/`, weights bị Git bỏ qua.
- vLLM chạy Linux/WSL2 hoặc service `reranker` trong profile Compose `rerank`; không cài vLLM vào venv API Windows.
- Compose dùng pooling runner, classifier yes/no và `deploy/qwen3_reranker.jinja`. API/worker có profile `app` riêng.
- `RERANK_API_KEY` ở dev là secret bảo vệ vLLM, không phải Hugging Face token. Chỉ bật `RERANK_ENABLED=true` sau `python -m rag.dev rerank-check` thành công.
- Serving chưa được nghiệm thu: driver 560.94 chưa đáp ứng image CUDA 13 đã chọn; Docker từng thiếu dung lượng ổ C. Xử lý driver/disk trước khi thử lại, xem hướng dẫn chính và trạng thái triển khai.

## 4. Chuyển sang API rerank sau này

Chưa chuyển provider hoặc gỡ model local trong lần sửa tài liệu này. Khi có provider thật:

1. Xác minh URL, model ID, kiểu auth, request/response schema và quota của provider.
2. Cấu hình `.env` riêng tư:

```dotenv
RERANK_ENABLED=false
RERANK_BASE_URL=https://api.provider.example/v1
RERANK_MODEL=PROVIDER_MODEL_ID
RERANK_API_KEY=PROVIDER_SECRET
# Nếu chạy API bằng Compose, phải đổi cả biến override này:
RERANK_CONTAINER_BASE_URL=https://api.provider.example/v1
```

3. Client hiện tự thêm `/rerank` nếu base URL kết thúc bằng `/v1`, hoặc thêm `/v1/rerank` nếu chưa có `/v1`. Không điền cả đường dẫn `/v1/rerank` vào base URL.
4. Contract hiện có: Bearer auth; POST body gồm `model`, `query`, `documents`, `top_n`; response có `results` chứa `index` và `relevance_score`. Index phải duy nhất, trỏ về candidates gốc; score là số hữu hạn; số kết quả bằng `min(top_n, số candidates)`. Provider khác contract cần sửa adapter `rag/reranker.py`, không chỉ đổi key.
5. Chạy `python -m rag.dev rerank-check` để gọi provider thật; lệnh có thể tính phí/quota. Chỉ bật rerank sau kiểm tra thành công và đánh giá chất lượng/độ trễ. Khởi động lại API để nạp cấu hình mới.

Chi tiết từng bước và dọn tài nguyên local: [mục 7 của hướng dẫn service](../real-estate-ai/docs/SETUP_FULL_STACK.md#7-chuyển-production).

## 5. Thư mục deploy khi đổi rerank

| File / tài nguyên | Khi còn dùng vLLM local | Khi chuyển hoàn toàn sang API |
|---|---|---|
| `deploy/qwen3_reranker.jinja` | Giữ: Compose mount làm template scoring | Có thể bỏ sau khi gỡ service/mount local và smoke API đạt |
| `models/Qwen3-Reranker-0.6B/` | Giữ weights local | Có thể dọn khi không cần rollback local |
| Service `reranker`, profile `rerank`, volume `vllm-cache` | Phục vụ local | Gỡ khỏi Compose nếu bỏ hẳn local; không xóa volume không liên quan |
| `deploy/property-event.schema.json` | Contract sự kiện RabbitMQ | Vẫn có ích, giữ nguyên hoặc chuyển sang `config/`/`docs/` và cập nhật tham chiếu |

`deploy/` chỉ là tên nhóm cấu hình, không phải bằng chứng đã deploy. Chỉ bỏ hẳn thư mục khi template local không còn được dùng và schema RabbitMQ đã được chuyển nơi khác hoặc có quyết định bỏ contract riêng. Không xóa schema chỉ vì thay provider rerank.

## 6. Qdrant, Gemini và nguồn dữ liệu

- Người dùng tự điền key/URL vào `.env` theo bảng trong hướng dẫn service; không đưa secret vào Git hoặc tài liệu.
- Key Gemini có thể dùng chung qua `GOOGLE_API_KEY`, hoặc tách `GOOGLE_LLM_API_KEY` và `GOOGLE_EMBEDDING_API_KEY`.
- Đổi key đơn thuần với cùng embedding contract không cần re-index. Đổi model/dimension/task/normalization cần collection **và** SQLite state mới; smoke dimension và re-index có giới hạn ngân sách.
- Không tự nhận collection đã tồn tại nhưng thiếu manifest tương ứng; không tự ghi đè/xóa index khi mismatch. Giữ dữ liệu FAISS cũ đến khi có quyết định chuyển/dọn riêng.
- Runtime kiểm tra trạng thái/quyền từ backend, không dùng payload Qdrant cũ để cho phép hiển thị tin đã gỡ. Không coi bản ghi vắng trong một trang snapshot là lệnh xóa.
- SQLite parent/version state hiện chỉ dành cho một máy/volume dùng chung. Scale nhiều máy cần store và concurrency control chung; không chạy nhiều state riêng trỏ cùng collection.

## 7. Các việc chưa nghiệm thu live

- Điền và kiểm tra Gemini model/key, Qdrant Cloud URL/Database API key, RabbitMQ Cloud AMQPS URL và quyền topology.
- Áp dụng migration DB theo engine thực tế; bật outbox publisher sau khi broker sẵn sàng.
- Smoke Gemini, sync batch nhỏ, chạy worker, xác nhận duyệt/sửa/gỡ tin cập nhật Qdrant thật.
- Khắc phục hạ tầng vLLM dev; smoke và đánh giá rerank 0.6B. Provider rerank production chưa được chọn hoặc nghiệm thu.
- Đánh giá chatbot với dữ liệu tiếng Việt đại diện; kiểm tra chat/stream và giới hạn quyền, latency, chi phí.

Không tự commit/push/deploy hoặc coi bằng chứng local/mock là nghiệm thu cloud. Checklist hiện hành: [CONG_VIEC_CHUA_HOAN_THANH.md](../real-estate-ai/docs/CONG_VIEC_CHUA_HOAN_THANH.md).
