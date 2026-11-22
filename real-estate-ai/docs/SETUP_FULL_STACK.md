# Chatbot AI: Gemini + Qdrant Cloud + Qwen3/vLLM + RabbitMQ Cloud

Cập nhật 14/11/2026. Hướng dẫn này thay hướng dẫn mock/manual-only cho luồng dữ liệu thật. API chat hiện giữ contract `/api/chat-rag` và `/api/chat-rag/stream`; không thay giao diện mobile/web trong lần này.

## 1. Các thành phần

```mermaid
flowchart LR
    A[Admin duyệt/sửa/xóa property] --> TX[DB property + indexing outbox cùng transaction]
    TX --> PUB[Publisher: confirms và mandatory returns]
    PUB --> MQ[RabbitMQ Cloud: AMQPS]
    MQ --> W[Python indexing worker]
    W --> SRC[Backend Property API nội bộ có token]
    W --> EMB[Gemini embedding]
    W --> Q[Qdrant Cloud]
    W --> S[Supabase PostgreSQL]
    CHAT[Chat API] --> Q
    CHAT --> SRC
    CHAT --> R[Qwen3-Reranker-0.6B qua vLLM local]
    CHAT --> LLM[Gemini LLM]
```

- Gemini gọi trực tiếp; Qdrant chỉ lưu vector, không nhận Gemini key.
- Qwen chạy bằng **vLLM pooling**, classifier yes/no và chat template Qwen3, không dùng chat completion để giả lập điểm rerank.
- Worker là tiến trình riêng, ACK sau khi Qdrant và state hoàn tất. Lỗi phụ thuộc được retry có backoff, quá giới hạn vào DLQ. Publisher retry bền vững bằng DB outbox.
- Nguồn chuẩn là backend; cả worker và retrieval xác minh trạng thái hiện tại. Tin chưa duyệt/đã xóa không có nội dung công khai trong nguồn AI.
- Version chỉ tăng khi dữ liệu được index thay đổi; giữ tombstone, ID ổn định và content hash. Metadata-only không tạo embedding lại.

## 2. Điền `.env`: lấy ở đâu

Làm trong `real-estate-ai/`. Nếu đã có `.env`, **giữ nguyên key cũ**, đối chiếu `.env.example` và thêm/sửa từng biến; không copy đè. Nếu chưa có, copy `.env.example` thành `.env`. Không gửi key lên chat hoặc commit `.env`.

`.env.example` và `.env` hiện tập trung vào 19 biến cho cấu hình đã chọn. Các override Google key riêng, URL container hoặc tham số tuning trong hướng dẫn là tùy chọn: chỉ thêm khi cần; nếu không có thì mã/Compose dùng giá trị mặc định. Hai secret nội bộ `PROPERTY_API_TOKEN` và `RERANK_API_KEY` đã được tạo riêng trong `.env` thật nếu trước đó còn thiếu; template chỉ chứa placeholder.

| Biến | Cách lấy/điền |
|---|---|
| `GOOGLE_API_KEY` | Vào [Google AI Studio – API keys](https://aistudio.google.com/api-keys), chọn/tạo Google Cloud project, tạo key cho Gemini API. Kiểm tra billing/quota của project. |
| `GEMINI_LLM_MODEL` | Lấy đúng model ID khả dụng trong project/AI Studio; không dùng tên hiển thị. Chọn model hỗ trợ chat, streaming và structured output. |
| `GEMINI_EMBEDDING_MODEL` | Giữ `models/gemini-embedding-001` nếu project hỗ trợ; smoke kiểm tra dimension thật trước khi tạo collection. |
| `GOOGLE_LLM_API_KEY`, `GOOGLE_EMBEDDING_API_KEY` | Có thể để trống để dùng chung `GOOGLE_API_KEY`. Production điền hai key riêng nếu muốn tách project/quota; không cần sửa code. |
| `QDRANT_URL` | Vào [Qdrant Cloud](https://cloud.qdrant.io/), tạo cluster, copy HTTPS cluster endpoint từ trang cluster. Dùng đúng REST endpoint/port do console cung cấp. |
| `QDRANT_API_KEY` | Tạo **Database API key** của cluster, có quyền đọc/ghi collection cần dùng. Không dùng Cloud Management key. |
| `QDRANT_COLLECTION` | Tự đặt, ví dụ `realestate_gemini_dev_v1`. Collection thật không có hậu tố `_mock`; dev/prod tách collection. CLI sẽ tạo collection theo dimension đã smoke. |
| `QDRANT_STATE_DATABASE_URL` | Chuỗi kết nối PostgreSQL dùng chung cho API và worker. |
| `QDRANT_STATE_DATABASE_CA_FILE` | Đường dẫn chứng chỉ CA để xác minh máy chủ PostgreSQL qua TLS. |
| `PROPERTY_API_URL` | URL backend tới `/api/internal/ai`, ví dụ `http://127.0.0.1:8080/api/internal/ai`. Nếu backend có context path thì thêm trước `/api`. |
| `PROPERTY_API_TOKEN` | Secret ngẫu nhiên do bạn tạo, dùng chung giữa backend và AI, khác JWT/Gemini key. |
| `RERANK_API_KEY` | Dev: secret ngẫu nhiên bảo vệ vLLM local, không phải HF token. Khi chuyển API: dùng secret provider cấp nếu provider hỗ trợ Bearer auth; xem mục 7. |
| `RABBITMQ_URL` | Copy nguyên AMQPS connection URL từ console RabbitMQ cloud: `amqps://USER:PASSWORD@HOST:5671/VHOST` (dùng port/vhost thực tế provider cung cấp). Đây là tài khoản AMQP, không phải management API key. Backend và worker dùng cùng URL. Nếu tự ghép URL, percent-encode ký tự đặc biệt; vhost `/` dùng `%2F`. |

Tạo từng secret riêng bằng PowerShell (chỉ chạy trên máy bạn):

```powershell
python -c "import secrets; print(secrets.token_hex(32))"
```

Model Qwen công khai không bắt buộc HF token. Nếu cần token để tăng hạn mức tải, tạo token read ở [Hugging Face settings](https://huggingface.co/settings/tokens), đặt `HF_TOKEN` trong môi trường của tiến trình tải; không đưa vào code.

Nguồn chính thức: [Gemini keys](https://ai.google.dev/gemini-api/docs/api-key), [Qdrant Cloud quickstart](https://qdrant.tech/documentation/cloud-quickstart/), [Qdrant database authentication](https://qdrant.tech/documentation/cloud/authentication/).

## 3. Backend: migration và cấu hình nguồn

Trong `real-estate-backend/`, áp dụng **một** migration theo DB đang dùng:

- MySQL: `db/migrations/004_property_index_mysql_forward.sql`.
- PostgreSQL: `db/migrations/004_property_index_postgresql_forward.sql`.

Backup trước khi chạy. Migration thêm `property.index_version` và bảng `property_index_outbox`; chạy một lần, chưa được tự động thực thi bằng Flyway. Không trông chờ `ddl-auto=update` để thay migration production.

Thêm profile `chatbot-index` vào các profile backend hiện có. Profile này đọc file `../real-estate-ai/.env` khi cwd là `real-estate-backend`; biến môi trường hệ thống có độ ưu tiên cao hơn. Nếu chạy từ thư mục khác, truyền đường dẫn import tuyệt đối hoặc export biến môi trường và cấu hình tương ứng. Khởi động backend bằng lệnh Maven/IDE hiện có, thêm `--spring.profiles.active=...,chatbot-index` phù hợp profile của bạn; không ghi đè profile storage/DB hiện dùng.

Đặt `PROPERTY_INDEX_ENABLED=true` sau khi broker và migration sẵn sàng. Dù publisher đang tắt, các thao tác property vẫn ghi outbox, tránh mất thay đổi trong lúc bảo trì. Dọn các event `SENT` theo chính sách lưu trữ; không xóa `PENDING` để bỏ qua lỗi.

Contract nguồn, header `X-AI-Service-Token`:

- `GET /api/internal/ai/properties/{id}`: `{id, version, public, text, metadata}`. Tin không công khai trả `public=false`, text/metadata rỗng. Không có email chủ tin hoặc nhận xét duyệt.
- `GET /api/internal/ai/properties?after=0&limit=20`: phân trang keyset, tối đa 100; trả `records`, gồm cả tombstone.
- `GET /api/internal/ai/properties/resolve?ids=1,2`: hydrate tối đa 100 ID/lượt cho retrieval.
- Token thiếu/sai hoặc token server rỗng: 401. Nguồn lỗi không được coi là lệnh xóa. ID không tồn tại: 404, worker chuyển DLQ để điều tra.

Chỉ cho service AI truy cập API nội bộ qua network policy/reverse proxy; dùng HTTPS khi khác máy. Tránh cập nhật trực tiếp DB bỏ qua PropertyService: thao tác đó không tạo version/outbox. Khi đổi dữ liệu danh mục/phường dùng chung, cần đánh version/reconcile các property bị ảnh hưởng trước khi coi index là mới.

## 4. RabbitMQ Cloud

**Phương án đã chọn:** broker RabbitMQ managed trên cloud, không chạy RabbitMQ bằng Docker. Compose hiện không chứa broker, cổng 5672/15672, volume RabbitMQ hoặc dependency bắt buộc vào broker local. API/worker và vLLM vẫn có tùy chọn container riêng; điều này không tạo broker local.

1. Trong nhà cung cấp bạn chọn, tạo instance **RabbitMQ**, chọn region phù hợp vị trí backend/AI. Nếu console có lựa chọn engine khác như LavinMQ, không mặc định nó có đầy đủ tính năng quorum của RabbitMQ.
2. Mở trang connection/details/overview, lấy AMQPS URL gồm hostname, AMQP user/password, port và vhost. Ví dụ với CloudAMQP, thông tin nằm ở [Overview trong console](https://www.cloudamqp.com/docs/cloudamqp-intro/). Không dùng HTTPS Management URL làm connection URL.
3. Copy nguyên URL vào `RABBITMQ_URL` của `.env`; không cần `RABBITMQ_USER/PASSWORD/VHOST` hay `RABBITMQ_CONTAINER_URL` riêng. Worker trong container cũng nhận đúng URL cloud này qua `env_file`.
4. Cấp quyền configure/write/read cho user trên vhost đã chọn để khai báo exchange/queue/binding, publish, consume và retry/DLQ. Nếu có IP allowlist hoặc private network, cho phép outbound từ backend và máy chạy AI; dùng port provider công bố, không mặc định luôn là 5671.
5. Kiểm tra gói/engine hỗ trợ quorum queues, TTL, publisher confirms và at-least-once dead-lettering. Giữ `RABBITMQ_QUEUE_TYPE=quorum` khi hỗ trợ. Nếu provider chỉ cho classic, có thể chọn `classic` cho dev nhưng retry TTL/DLX không còn cùng bảo đảm bàn giao như quorum; cần quyết định rõ, không tự hạ cấp hoặc tuyên bố cùng độ bền. Xem [RabbitMQ quorum dead-lettering](https://www.rabbitmq.com/docs/quorum-queues).
6. TLS client Python và Java xác minh chứng chỉ/hostname; nếu provider dùng CA riêng cần cấu hình trust store tương ứng, không tắt verify. Không thay host cloud thành `host.docker.internal` hoặc localhost.

Sau khi điền `.env`, chạy từ môi trường Python phù hợp:

```powershell
python -m rag.broker check
```

Lệnh này kết nối thật và **khai báo topology** trên vhost được chọn, rồi in số message ready, không in URL/password. Nếu dùng venv Windows bị chặn gRPC, dùng WSL hoặc lệnh profile `app` ở mục 6. Sau khi check thành công và migration backend sẵn sàng mới bật `PROPERTY_INDEX_ENABLED=true`, rồi chạy worker.

Topology v1:

- Topic exchange `property.events.v1`; routing `property.approved/updated/unpublished/deleted`.
- Queue chính `ai.property.index.v1`, mặc định quorum, prefetch=1.
- Retry exchange/queue `ai.property.index.retry.v1`, TTL mặc định 30 giây, quay về main queue. Quorum retry dùng at-least-once dead-lettering và reject-publish khi đầy.
- DLQ exchange/queue `ai.property.index.dlq.v1`; lỗi vĩnh viễn hoặc hết `RABBITMQ_MAX_RETRIES` vào DLQ.
- Worker republish retry/DLQ với confirms + mandatory, chỉ ACK bản gốc sau bàn giao thành công. Không có bảo đảm exactly-once end-to-end.
- Lệnh kiểm tra broker: `python -m rag.broker check`. Sau khi sửa nguyên nhân lỗi, redrive có giới hạn bằng `python -m rag.broker redrive --limit 10`; event sai schema được giữ trong DLQ để sửa, không tự bỏ qua.
- Không tự replay lịch sử sau ACK. Rebuild từ backend snapshot/reconcile. Muốn redrive DLQ: sửa nguyên nhân, republish có confirms và route đúng, giữ eventId/version, reset header `x-index-retries`, chỉ ACK DLQ sau publish thành công. Không purge DLQ để coi lỗi đã xử lý.

Instance/gói cloud một node không có khả năng chịu mất máy như cụm quorum nhiều node; cloud không tự đồng nghĩa với HA. Đổi queue type/TTL cần kế hoạch migration topology, không sửa tùy tiện trên queue đang có dữ liệu.

## 5. Qwen3-Reranker-0.6B qua vLLM

Trước khi build image, chuẩn bị khoảng 30–40 GB trống tại nơi Docker lưu disk image/layers. Ổ C của máy hiện đã gần đầy trong lần thử; cần giải phóng thêm hoặc chuyển nơi lưu disk image sang ổ D bằng Docker Desktop. Đặt model/repo ở D không tự chuyển Docker layers khỏi C.

Model nằm trong `models/Qwen3-Reranker-0.6B/`, Git bỏ qua weights/cache. Tải theo commit đã pin:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\hf.exe download Qwen/Qwen3-Reranker-0.6B --revision e61197ed45024b0ed8a2d74b80b4d909f1255473 --local-dir ./models/Qwen3-Reranker-0.6B
docker compose --profile rerank pull reranker
docker compose --profile rerank up -d reranker
docker compose logs --tail 80 reranker
```

Compose dùng vLLM `0.21.0`, `--runner pooling`, overrides `Qwen3ForSequenceClassification`, `classifier_from_token=[no,yes]`, `is_original_qwen3_reranker=true` và template checked-in. GPU dev RTX 4050 6 GB dùng FP16 không lượng tử hóa, `dtype=half`, context 2048, một sequence, eager mode. Model mặc định đã chuyển sang 0.6B theo lựa chọn của bạn. File `.env` hiện được giữ gọn; các tham số tuning không khai báo dùng mặc định trong `rag/config.py` (20 candidates, top 5, timeout 5 giây, 4000 ký tự/document). Nếu cần giảm đầu vào cho vLLM 2048 token, có thể thêm `RERANK_DOCUMENT_CHARS=1800` và điều chỉnh timeout/candidate limit sau khi đo thực tế. Giới hạn ký tự không bảo đảm mọi cặp query/document vừa 2048 token; quá giới hạn được báo lỗi và client fallback.

vLLM chạy Linux; không cài vLLM vào `.venv` Windows. Image vLLM 0.21.0 đã chọn dùng CUDA 13; driver hiện tại 560.94 không đáp ứng. Cần nâng driver NVIDIA Windows/WSL lên bản hỗ trợ CUDA 13 (nhánh 580 trở lên phù hợp GPU), rồi chạy smoke; không tắt kiểm tra CUDA để vượt lỗi. Xem [bảng tương thích NVIDIA](https://docs.nvidia.com/deploy/cuda-compatibility/minor-version-compatibility.html). Docker cần GPU passthrough/driver WSL tương thích. RAM máy 16 GB và các container khác có thể gây thiếu bộ nhớ ngoài phần weights của model; không tự dừng workload ngoài dự án. Nếu OOM/driver/kernel không tương thích, giữ `RERANK_ENABLED=false`, giải quyết hạ tầng rồi smoke lại. Không coi fallback là rerank thành công.

Kiểm tra endpoint thật (không gọi Gemini):

```powershell
.\.venv\Scripts\python.exe -m rag.dev rerank-check
```

Chỉ sau khi thành công mới bật `RERANK_ENABLED=true`. Client gọi `/v1/rerank`, gửi model `Qwen/Qwen3-Reranker-0.6B` và Bearer `RERANK_API_KEY`; kiểm tra index/score và fallback về candidates đã lọc khi timeout/503/response lỗi. Smoke chỉ xác minh serving, không chứng minh chất lượng; chạy bộ đánh giá tiếng Việt trước quyết định production.

Nguồn: [vLLM Qwen reranker](https://docs.vllm.ai/en/v0.21.0/examples/pooling/score/), [model chính thức](https://huggingface.co/Qwen/Qwen3-Reranker-0.6B).

## 6. Khởi tạo Qdrant Cloud và chạy pipeline

Từ `real-estate-ai/`, cài `requirements.txt` trong venv phù hợp. Nếu Windows chặn DLL gRPC, dùng Linux/WSL hoặc image Docker của service; không tắt chính sách Application Control.

Các lệnh có `--allow-api-calls` gọi Gemini và có thể tính phí; chạy sau khi kiểm tra quota/ngân sách:

```powershell
.\.venv\Scripts\python.exe -m rag.dev setup-check
.\.venv\Scripts\python.exe -m rag.dev gemini-smoke --allow-api-calls
.\.venv\Scripts\python.exe -m rag.dev sync-backend --allow-api-calls --limit 20 --after 0
```

`setup-check` kiểm tra cấu hình và manifest PostgreSQL. `gemini-smoke` kiểm tra kích thước vector, LLM, structured output và stream rồi ghi `embedding-smoke.json`. `sync-backend` tạo collection và manifest phù hợp, đồng bộ một trang. Dùng `next_after` để tiếp tục. Nếu có lỗi, sửa lỗi rồi chạy lại từ cursor trả về.

Khởi động worker sau smoke, trước hoặc trong lúc snapshot để queue giữ các thay đổi:

```powershell
.\.venv\Scripts\python.exe -m rag.worker
```

Worker/sync có thể tạo embedding tính phí. Nguồn phải là `INDEX_SOURCE_PROVIDER=backend` và collection không có `_mock`. API startup không tự embed toàn bộ. Sau khi sync ban đầu:

```powershell
.\.venv\Scripts\python.exe -m rag.dev qdrant-check
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000
```

Mở `http://127.0.0.1:8000/docs` để gọi API hiện có. Stream hiện là text streaming, không phải SSE có structured events. Thực hiện duyệt một tin thử, kiểm tra outbox `SENT`, queue giảm và nội dung xuất hiện; sửa rồi xóa mềm tin, xác minh chatbot không trả tin bị gỡ. Lỗi Qdrant/embedding phải để lại retry/DLQ, không đánh dấu hoàn tất giả.

Khi chạy AI trong container, `127.0.0.1` là chính container: dùng `host.docker.internal` cho backend/vLLM chạy trên host. Qdrant Cloud và RabbitMQ Cloud giữ nguyên hostname/URL của provider, không thay bằng địa chỉ host local. Ví dụ kiểm thử Linux ở máy này dùng Docker để tránh DLL Windows, không thay `.env` của bạn.

### Chạy API và worker bằng Docker Linux (tránh DLL Windows)

Sau khi Docker Engine ổn định, có thể dùng profile `app` thay `.venv` Windows. `PROPERTY_API_CONTAINER_URL` phải trỏ đúng backend Windows, mặc định `http://host.docker.internal:8080/api/internal/ai`; thêm context path nếu backend có. `RERANK_CONTAINER_BASE_URL` mặc định trỏ cổng vLLM trên host. Worker nhận nguyên `RABBITMQ_URL` cloud từ `.env`; không phụ thuộc service broker trong Compose và không cần URL container riêng.

```powershell
docker compose --profile app build worker api
.\.venv\Scripts\python.exe -m rag.dev gemini-smoke --allow-api-calls
.\.venv\Scripts\python.exe -m rag.dev sync-backend --allow-api-calls --limit 20 --after 0
docker compose --profile app up -d worker
# Lặp sync-backend theo next_after đến trang rỗng, rồi:
docker compose --profile app up -d api
docker compose --profile app run --rm worker python -m rag.broker check
```

Kiểm tra broker bằng `docker compose --profile app run --rm worker python -m rag.broker check` trước khi gọi Gemini. API và worker nhận cấu hình từ `.env` lúc chạy và dùng cùng trạng thái trên PostgreSQL.

## 7. Chuyển production

### 7.1. LLM và embedding

Lưu key Gemini production trong `.env` hoặc secret store. Có thể dùng riêng `GOOGLE_LLM_API_KEY` và `GOOGLE_EMBEDDING_API_KEY` hoặc dùng chung `GOOGLE_API_KEY`. Khi đổi model, kích thước vector, tác vụ hoặc cách chuẩn hóa, tạo collection và database trạng thái riêng rồi kiểm tra và lập chỉ mục lại trước khi chuyển traffic.

### 7.2. Thay rerank local bằng API

**Hiện tại vẫn dùng Qwen3-Reranker-0.6B/vLLM local; API rerank là bước chuyển sau này.** Chưa có provider production được chọn hoặc kiểm chứng.

1. Lấy base URL, model ID và key từ provider. Xác minh endpoint, request/response, auth, quota và quy định dữ liệu gửi ra ngoài.
2. Đặt cấu hình riêng tư; tạm giữ rerank tắt đến khi smoke đạt:

```dotenv
RERANK_ENABLED=false
RERANK_BASE_URL=https://api.provider.example/v1
RERANK_MODEL=PROVIDER_MODEL_ID
RERANK_API_KEY=PROVIDER_SECRET
# Bắt buộc đổi cả biến này nếu API chạy bằng profile app của Compose:
RERANK_CONTAINER_BASE_URL=https://api.provider.example/v1
```

Ví dụ dùng `.example` là placeholder, không phải endpoint thật. Không đưa key vào Git/chat. `RERANK_API_KEY` lúc này là key provider, thay cho secret bảo vệ vLLM local.

**Contract client hiện tại** trong `rag/reranker.py`:

- Header `Authorization: Bearer ...`.
- Base kết thúc bằng `/v1` → POST `/rerank`; base chưa có `/v1` → POST `/v1/rerank`. Không điền nguyên endpoint `/v1/rerank` vào base URL vì client sẽ nối đường dẫn lần nữa.
- Request: `{model, query, documents: [text, ...], top_n}`.
- Response: `{results: [{index, relevance_score}, ...]}` với `index` là số nguyên duy nhất, trỏ đúng thứ tự documents đầu vào, score là số hữu hạn. Số kết quả phải bằng `min(top_n, số documents)`.
- Schema/path/auth khác cần sửa adapter; không coi việc đổi API key là đủ để tương thích.

3. Chạy `python -m rag.dev rerank-check` bằng venv/môi trường phù hợp, hoặc với Compose:

```powershell
docker compose --profile app run --rm api python -m rag.dev rerank-check
```

Lệnh gọi API rerank thật và có thể dùng quota/tính phí, dù `RERANK_ENABLED=false`; kiểm tra ngân sách trước khi chạy. Smoke xác minh serving/mapping, không chứng minh chất lượng. Cần đánh giá thêm với dữ liệu tiếng Việt đại diện và điều chỉnh timeout/candidate limit theo latency/quota.

4. Khi đạt, đặt `RERANK_ENABLED=true`, khởi động lại API để nạp `.env`. Nếu chạy Compose, tạo lại service để nạp env mới:

```powershell
docker compose --profile app up -d --force-recreate api
```

Không bật profile `rerank` khi chỉ dùng provider API. Rerank lỗi vẫn fallback về candidates đã lọc; theo dõi log để tránh nhầm fallback với rerank đã chạy thành công.

### 7.3. Có còn cần thư mục deploy không?

`deploy/` chỉ nhóm file cấu hình và contract; tên thư mục không có nghĩa dự án đã được deploy.

| Tài nguyên | Vai trò hiện tại | Sau khi chuyển hoàn toàn sang API rerank |
|---|---|---|
| `deploy/qwen3_reranker.jinja` | Template Qwen3 được Compose mount cho vLLM local | Có thể bỏ sau khi gỡ mount/service local và smoke provider đạt |
| `models/Qwen3-Reranker-0.6B/` | Weights model local | Có thể bỏ khi không cần rollback local; không xóa `.env` hoặc dữ liệu vector |
| Service `reranker`, profile `rerank`, volume `vllm-cache` trong Compose | Chạy và cache vLLM local | Gỡ cấu hình khi bỏ hẳn local; dừng service trước, chỉ dọn đúng volume liên quan nếu cần |
| `deploy/property-event.schema.json` | Contract message đồng bộ property qua RabbitMQ | Giữ nguyên hoặc chuyển sang `config/`/`docs/`, cập nhật tham chiếu; vẫn độc lập với provider rerank |

Chỉ bỏ hẳn `deploy/` sau khi không còn template local được dùng và schema RabbitMQ đã được chuyển nơi khác hoặc có quyết định quản lý contract khác. Không xóa cả thư mục khi Compose vẫn mount template. Lần cập nhật tài liệu này **không** xóa model, template, schema hoặc chuyển cấu hình chạy sang API.

### 7.4. State và vận hành

- Mọi replica dùng chung trạng thái PostgreSQL cho cùng collection Qdrant.
- Sao lưu và khôi phục Qdrant cùng trạng thái PostgreSQL tương ứng. Đối chiếu dữ liệu bằng cách quét từ `after=0`. Sự kiện xóa tin đến từ backend.
- Qdrant Cloud và RabbitMQ Cloud vẫn giữ nguyên vai trò khi đổi rerank. Dùng key/vhost/quyền riêng cho production; nghiệm thu reconnect, retry/DLQ và cập nhật/gỡ tin trên dịch vụ thật.
- Auth/rate limit/public exposure, lưu hội thoại theo tài khoản, structured cards và benchmark cần nghiệm thu riêng. Mã và bằng chứng local hiện có không đồng nghĩa chatbot production-ready.

## 8. Bằng chứng nghiệm thu

Xem `IMPLEMENTATION_STATUS.md` để biết lệnh nào đã chạy, kết quả local/mock và dịch vụ thật còn cần key. Không suy từ test giả lập sang chất lượng model hoặc kết nối Qdrant Cloud.
