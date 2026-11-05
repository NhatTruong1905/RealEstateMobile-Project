# Thiết lập chatbot Gemini / Qdrant / vLLM

## 1. Cấu hình Gemini trên máy của bạn

Mở [Google AI Studio – API Keys](https://aistudio.google.com/apikey), chọn project dev và tạo key. Xem model mà project được phép sử dụng cùng quota/giá trước khi chọn. Hướng dẫn Google: [API key](https://aistudio.google.com/docs/api-key), [model](https://aistudio.google.com/docs/models), [giá](https://ai.google.dev/gemini-api/docs/pricing).

Mở `real-estate-ai/.env` bằng editor, **giữ các cấu hình đang có**, thêm hoặc cập nhật từng biến dưới đây. Không gửi key vào chat và không copy đè `.env` hiện có bằng `.env.example`.

```dotenv
LLM_PROVIDER=gemini
GOOGLE_API_KEY=<key nhập trực tiếp ở máy bạn>
GEMINI_LLM_MODEL=<model ID khả dụng cho project của bạn>
GEMINI_EMBEDDING_MODEL=models/gemini-embedding-001
VECTOR_STORE_PROVIDER=qdrant
QDRANT_URL=http://localhost:6333
QDRANT_API_KEY=
QDRANT_COLLECTION=realestate_gemini_dev_v1_mock
QDRANT_STATE_PATH=./vector_database/qdrant-dev-mock.sqlite3
INDEX_SOURCE_JSON=./data/listings_mock.json
RERANK_ENABLED=false
```

Giữ một tên key là `GOOGLE_API_KEY`; ứng dụng dùng nó cho cả LLM và embedding. Kiểm tra offline hiện thấy biến key đã có giá trị, nhưng **chưa kiểm chứng key hợp lệ hoặc quota**. Còn thiếu model và nguồn/collection dev. `.env` đã được Git ignore; không sửa key thật trong quá trình refactor.

## 2. Chuẩn bị Qdrant

Qdrant là nơi lưu vector, không phải nơi lấy dữ liệu tin đăng. Bạn cần endpoint; chỉ Qdrant Cloud/server có auth mới cần database API key. Không nhập key Gemini vào Qdrant.

**Docker local:** mở Docker Desktop và chờ Engine chạy. Kiểm tra `docker version` có phần Server. Tại lần kiểm tra này CLI có sẵn nhưng daemon chưa chạy. Bước tiếp theo là chọn/pin image Qdrant, tạo volume bền vững và chỉ mở cổng `127.0.0.1:6333`. Lệnh tham khảo và cách dừng/chạy lại ở [README_GEMINI_DEV.md](README_GEMINI_DEV.md#qdrant-local-và-network); chưa có server image được smoke test trên máy này. Không xóa container/volume hiện hữu.

**Qdrant Cloud:** làm theo [Cloud Quickstart](https://qdrant.tech/documentation/cloud-quickstart/), tạo cluster dev trong gói/vùng bạn chọn. Copy cluster endpoint HTTPS và database API key vào `QDRANT_URL` / `QDRANT_API_KEY` trong `.env`. Dùng database key có quyền đọc/ghi collection phục vụ sync; management key quản lý Cloud không thay cho database key. Giữ tên collection `_mock` trong giai đoạn thử.

Chưa cần tự tạo vector dimension hay upload vector. Script đo dimension bằng Gemini smoke rồi tạo collection tương thích. Bản hiện tại dùng fixture JSON; nguồn tin thật cần adapter xác nhận trạng thái/quyền xem từ backend trước khi chuyển sang dữ liệu thật. Không đổi nhãn dữ liệu thật thành `kind=mock` để bỏ qua bước này. SQLite chứa parent/mapping phải được giữ và backup cùng collection Qdrant.

## 3. Kiểm tra và chạy

PowerShell, dùng đúng virtualenv **trong `real-estate-ai`**, không dùng `.venv` ở root:

```powershell
cd D:\RealEstateMobile-Project\real-estate-ai
.\.venv\Scripts\python.exe -m rag.dev setup-check
```

Lệnh này không gọi mạng/API, không in giá trị key. Exit code 1 nghĩa là còn mục cần cấu hình. `configured_offline` chỉ xác nhận điều kiện offline, không chứng minh dịch vụ thật hoạt động.

Sau khi bạn tự xác nhận ngân sách/quota và Qdrant sẵn sàng, chạy theo thứ tự:

```powershell
.\.venv\Scripts\python.exe -m rag.dev gemini-smoke --allow-api-calls
.\.venv\Scripts\python.exe -m rag.dev sync --allow-api-calls --limit 3 --max-chunks 10
.\.venv\Scripts\python.exe -m rag.dev qdrant-check
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000
```

Chỉ đi tiếp khi lệnh trước thành công. Smoke/sync có gọi Gemini và có thể tính phí. Seed 3 bản ghi chỉ là batch đầu; xem `remaining` và dùng `--offset` cho batch tiếp theo. API khởi động không tự seed/re-embed. Thử chat tại `http://127.0.0.1:8000/docs`; endpoint giữ nguyên `/api/chat-rag` và `/api/chat-rag/stream`.

## 4. Reranker

Giữ `RERANK_ENABLED=false` để hoàn tất Gemini/Qdrant trước. Máy có RTX 4050 Laptop 6141 MiB, driver 560.94; chưa có bằng chứng vLLM/Qwen chạy đúng template hoặc vừa VRAM. vLLM cài trong WSL/Linux riêng, không cài vào virtualenv API Windows. Xem [hướng dẫn vLLM và phần chưa nghiệm thu](README_GEMINI_DEV.md#vllm-local-phần-còn-thiếu). Chỉ bật rerank sau smoke thật; timeout/503 vẫn dùng danh sách đã lọc ban đầu.

## 5. Cấu trúc để mở rộng

| File | Trách nhiệm |
| --- | --- |
| `rag/config.py` | Đọc và kiểm tra cấu hình |
| `rag/providers.py` | Tạo client LLM/embedding theo provider |
| `rag/embedding_contract.py` | Manifest tương thích embedding |
| `rag/source.py` | Kiểm tra schema nguồn dữ liệu dev |
| `rag/retriever.py` | Chọn/nạp retriever, không index ở startup |
| `rag/qdrant_store.py` | Lưu/tìm child vector và parent bền vững, sync có version |
| `rag/filters.py` | Nhận diện lời chào, lọc và loại trùng tin |
| `rag/reranker.py` | HTTP rerank, deadline, giới hạn đồng thời, fallback |
| `rag/context.py` | Retrieval → xác minh nguồn → lọc → rerank → giới hạn context |
| `rag/conversation.py` | Lịch sử có giới hạn và structured intent |
| `rag/prompts.py` | Prompt tư vấn |
| `rag/output.py` | Chuẩn hóa text trả lời |
| `rag/pipeline.py` | Ghép các thành phần và chạy chat sync/stream |
| `rag/setup_check.py` | Chẩn đoán offline, không mạng hoặc xuất secret |
| `rag/dev.py` | CLI smoke/sync/check chủ động |
| `rag/benchmark.py` | So sánh chất lượng/thời gian rerank trên bộ nhãn |

Thêm provider ở factory; thêm nguồn nghiệp vụ bằng adapter có xác nhận quyền; giữ transport Kafka tương lai tách khỏi logic sync. Các export cũ từ `rag.config`, `rag.pipeline`, `rag.qdrant_store` vẫn được giữ để tránh phá caller hiện có.

Kiểm chứng ngày 04/11/2026: test local và HTTP simulation không thay thế nghiệm thu Gemini, Qdrant server hoặc vLLM thật. Xem evidence cập nhật trong README.
