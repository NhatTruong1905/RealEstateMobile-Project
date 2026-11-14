# Bàn giao chatbot AI: cấu hình dev và hướng chuyển production

Cập nhật 14/11/2026. Hướng dẫn vận hành: [SETUP_FULL_STACK.md](SETUP_FULL_STACK.md). Điểm bắt đầu ngắn: [SETUP_CHATBOT.md](SETUP_CHATBOT.md). Các việc còn thiếu: [CONG_VIEC_CHUA_HOAN_THANH.md](CONG_VIEC_CHUA_HOAN_THANH.md).

## Cấu hình thống nhất

- Gemini API cho LLM và embedding; key nằm trong `.env`, có thể tách key theo hai vai trò.
- Qdrant Cloud lưu vector; SQLite giữ parent/version/manifest trên volume bền vững dùng chung trong một máy.
- RabbitMQ Cloud qua AMQPS nhận sự kiện từ backend transactional outbox; không có broker RabbitMQ local trong Compose.
- Qwen3-Reranker-0.6B qua vLLM local cho dev. Provider API rerank production là bước sau, chưa thay trong cấu hình đang có.
- Dependency API/tải model/công cụ được gom vào `requirements.txt`. vLLM chạy trong Linux runtime riêng, không cài vào venv Windows.
- `scripts/`, `tests/`, `postman/` của service AI đã được gỡ. Các kết quả kiểm thử lưu trong tài liệu là lịch sử trước khi gỡ, không phải suite hiện còn để chạy lại.

## Các module runtime chính

| File | Vai trò |
|---|---|
| `rag/config.py` | Đọc và kiểm tra cấu hình, che secret khỏi repr |
| `rag/providers.py` | Adapter Gemini/LLM và embedding |
| `rag/pipeline.py` | Khởi tạo và điều phối chat/text streaming |
| `rag/property_source.py` | Hydrate dữ liệu và trạng thái property từ backend có token |
| `rag/qdrant_store.py` | Qdrant + parent/version state, sync, cleanup và kiểm tra nguồn |
| `rag/reranker.py` | HTTP rerank, Bearer auth, kiểm tra mapping/score và fallback |
| `rag/messaging.py`, `rag/worker.py` | Topology RabbitMQ và xử lý sự kiện nền |
| `rag/broker.py` | Kiểm tra broker, redrive DLQ có giới hạn |
| `rag/dev.py` | Setup check, smoke Gemini/rerank, bounded sync và Qdrant check |
| `compose.yaml` | Profile `app` cho API/worker, profile `rerank` cho vLLM local |

Backend Java đã có migration `004_property_index_*`, outbox/publisher và API nguồn nội bộ. Cần áp dụng migration đúng DB, điền URL/key/token và nghiệm thu Cloud thật trước khi dùng dữ liệu thật.

## Bằng chứng và giới hạn

Đã có kiểm thử local/mock cho retrieval, version/tombstone, retry/ACK/fallback và test broker RabbitMQ local thật; bộ regression backend đã có lần đạt. Chi tiết số lượng/kết quả và môi trường nằm trong [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md), giữ riêng với nghiệm thu live.

Chưa nghiệm thu Gemini/Qdrant Cloud/RabbitMQ Cloud bằng tài khoản người dùng. Chưa chạy inference Qwen 0.6B: image vLLM đã chọn cần xử lý driver và dung lượng Docker. Việc tải model hoặc Compose config hợp lệ không chứng minh serving/quality. Giữ `RERANK_ENABLED=false` đến khi rerank-check đạt.

API startup không tự embed toàn bộ; sync/worker có thể dùng quota Gemini. Nguồn backend là chuẩn về quyền/trạng thái, không dùng payload vector cũ để cho phép tin đã gỡ xuất hiện. Stream hiện là text streaming, chưa phải structured SSE. SQLite state hiện không dành cho nhiều replica với các file state riêng.

## Sau này đổi rerank sang API

1. Lấy provider/model/key và xác minh contract; không mặc định mọi API rerank đều tương thích.
2. Đổi `RERANK_BASE_URL`, `RERANK_MODEL`, `RERANK_API_KEY`. Khi API chạy bằng Compose phải đổi thêm `RERANK_CONTAINER_BASE_URL`, nếu không container vẫn có thể gọi URL local.
3. Client hiện dùng Bearer + `/v1/rerank` với `results[index,relevance_score]`; khác schema/auth/path cần adapter.
4. Smoke provider có kiểm soát quota, đánh giá chất lượng rồi bật rerank và restart/recreate API.
5. Sau khi bỏ hẳn local: có thể dọn model, template vLLM, service `reranker` và cache liên quan. Schema `deploy/property-event.schema.json` vẫn là contract RabbitMQ, giữ hoặc chuyển trước khi bỏ cả `deploy/`.

Quy trình, cấu hình mẫu và bảng file cần giữ/bỏ: [mục 7](SETUP_FULL_STACK.md#7-chuyển-production). Lần cập nhật tài liệu không thay provider, không xóa model/template hoặc chuyển schema.

## Tham chiếu ngoài service

- [Kế hoạch dev/production](../../docs/PLAN_GEMINI_VLLM_RERANK_DEV.md).
- [Nghiên cứu chatbot](../../docs/RESEARCH_AI_CHATBOT.md): thuật toán và provider ứng viên; baseline cũ không phải hiện trạng đã triển khai.
