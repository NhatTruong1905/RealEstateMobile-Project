# Trạng thái tích hợp chatbot AI — 14/11/2026

Hướng dẫn chính: [SETUP_FULL_STACK.md](SETUP_FULL_STACK.md). Người dùng chọn **Qwen3-Reranker-0.6B qua vLLM**, Gemini cho LLM/embedding, Qdrant Cloud và **RabbitMQ Cloud**. Người dùng sẽ điền `.env` sau; chưa chạy Gemini tính phí hoặc thao tác vào cluster Cloud thật trong lần này.

## Quyết định rerank hiện hành

Dev tiếp tục dùng Qwen3-Reranker-0.6B qua vLLM local. Rerank API production chưa được chọn hoặc nghiệm thu. Khi chuyển, cần đổi base URL/model/key và cả `RERANK_CONTAINER_BASE_URL` nếu dùng Compose, xác minh contract rồi smoke có kiểm soát chi phí trước khi bật. Không thay runtime hay `.env` trong lần sửa tài liệu này.

`deploy/qwen3_reranker.jinja` chỉ phục vụ vLLM local; có thể dọn cùng model/service sau khi chuyển hoàn toàn. `deploy/property-event.schema.json` phục vụ contract RabbitMQ, vẫn giữ hoặc chuyển sang nơi khác. Chỉ bỏ cả `deploy/` khi không còn mount/tham chiếu local và schema đã được xử lý. Hướng dẫn chuẩn: [mục 7 của setup](SETUP_FULL_STACK.md#7-chuyển-production).

## Mã đã bổ sung

- Backend: `index_version`, indexing outbox riêng, ghi cùng transaction duyệt/sửa/xóa mềm; publisher RabbitMQ có persistent messages, mandatory returns, confirms và retry outbox. No-op không tăng version hoặc thay audit timestamp.
- API nguồn nội bộ có shared token: hydrate theo ID, batch resolve và keyset snapshot; tin không công khai chỉ trả tombstone, không lộ email/nhận xét duyệt.
- AI worker: hydrate trạng thái mới nhất, embedding phần nội dung thay đổi, sync Qdrant và parent/version state, manual ACK; retry có TTL/backoff, DLQ, redrive có giới hạn.
- Qdrant dùng index `parent_id` để lọc và dọn vector. Phiên bản hiện tại dùng khóa giao dịch PostgreSQL khi cập nhật chỉ mục. Retrieval xác minh dữ liệu với backend trước khi trả kết quả.
- Rerank client: hỗ trợ Bearer API key để dùng vLLM local hoặc endpoint production tương thích schema.
- Compose: không chạy broker RabbitMQ; worker dùng URL cloud chung với backend. vLLM pooling 0.6B FP16 và profile `app` chạy API/worker bằng Linux, dùng chung volume state. Không đóng secrets/model weights vào image.
- `.env.example`: cấu hình Cloud, token nội bộ, broker, rerank và tùy chọn key LLM/embedding riêng. `.env` thật của người dùng không bị ghi đè.

## Model local

- Đã tải model chính thức `Qwen/Qwen3-Reranker-0.6B` vào `models/Qwen3-Reranker-0.6B/`.
- Revision: `e61197ed45024b0ed8a2d74b80b4d909f1255473`; weights `model.safetensors` có 1.191.588.280 byte. Manifest nằm cạnh model.
- Thư mục model và cache bị Git bỏ qua; chỉ README/downloader/config được theo dõi.
- Model 4B cũ nằm trong thư mục lưu trữ ngoài repo và chưa được xóa khỏi ổ D.

## Bằng chứng và giới hạn

| Hạng mục | Bằng chứng / kết quả |
|---|---|
| Backend compile | `JAVA_HOME=D:\Java\jdk-21.0.12.1`, `mvnw.cmd -q -DskipTests compile`: đạt. |
| Backend focused tests | `PropertyApprovalIntegrationTest`, `PropertyServiceImplTest`, `PropertyIndexMigrationTest`, `PropertyIndexDeliveryTest`: 24 test, không failure/error. Kiểm tra quyền nguồn, version, rollback, migration MySQL/PostgreSQL trên H2 và retry publisher. |
| Java publisher → RabbitMQ thật | Lần chạy riêng cuối `RabbitPropertyIndexSenderTest`: **1 passed** (1,33 giây), nhận message persistent/eventId/version qua RabbitMQ 4.2.1 thật. Đã kiểm tra lại sau lỗi Docker tạm thời; không gọi Cloud/Gemini. |
| HTTP rerank simulation | Postman CLI 1.75.0, synthetic HTTP: mapping đúng; 503 và timeout fallback đúng. Đã chạy lại cả ba tình huống sau thay đổi connection pooling, đều đạt. Đây là bằng chứng lịch sử; thư mục mock/simulation Postman đã được gỡ theo yêu cầu người dùng. Không phải model inference. |
| Python suite | WSL Python 3.12.16: **57 passed, 1 skipped** (18,61 giây). Test live RabbitMQ được skip khi không có URL test. Đã sửa đường dẫn fixture cũ sang dữ liệu canonical và tái sử dụng HTTP client rerank; Qdrant embedded/fake embedding không thay nghiệm thu Cloud. Windows bị Application Control chặn native gRPC DLL; không tắt chính sách bảo vệ. |
| Compose | `docker compose --profile app --profile rerank config --quiet` với env test riêng: đạt; không in secrets. |
| Full backend suite | Lần chạy cuối `mvnw.cmd -q test` **đạt** (exit 0), gồm cả regression storage. Test mới đã được sửa; lỗi storage xuất hiện ở một lần trước không lặp lại trong lần cuối. Test broker opt-in không bật trong suite này, được chạy riêng. |
| RabbitMQ retry TTL/DLQ live | Docker Linux + RabbitMQ 4.2.1 thật: **1 passed** (2,97 giây). Đã kiểm tra confirms, retry queue TTL quay về queue chính, worker ACK và ghi Qdrant embedded, malformed event vào DLQ. Dùng topology tên ngẫu nhiên và tự dọn, không purge queue ứng dụng. Embedding/source là synthetic; không phải Cloud/Gemini live. |
| vLLM serving | Chưa nghiệm thu. Image vLLM 0.21.0 dùng CUDA 13; driver NVIDIA 560.94 hiện không đủ. Theo NVIDIA, CUDA 13 cần nhánh driver 580 trở lên; nâng driver phù hợp rồi smoke 0.6B. Lần tạo container trả Docker API 502 khi ổ C hết dung lượng; chưa tạo được serving container hoặc đo VRAM/quality. Không đổi sang runtime khác hoặc tắt kiểm tra CUDA. |
| Qdrant Cloud / Gemini live | Chờ người dùng tự điền `.env`, sau đó chạy smoke/bounded sync theo hướng dẫn. Không có bằng chứng dimension/latency/cost/quality thật từ lần này. |

Nguồn hạ tầng: [NVIDIA CUDA compatibility](https://docs.nvidia.com/deploy/cuda-compatibility/minor-version-compatibility.html), [vLLM Qwen pooling](https://docs.vllm.ai/en/v0.21.0/examples/pooling/score/), [RabbitMQ confirms](https://www.rabbitmq.com/docs/confirms).

## Chạy lại các kiểm tra cần hạ tầng

Từ `real-estate-ai/`, sau khi điền `.env` và Docker hoạt động:

```powershell
python -m rag.broker check
docker compose --profile rerank pull reranker
docker compose --profile rerank up -d reranker
python -m rag.dev rerank-check
```

Các kết quả kiểm thử nêu trên là bằng chứng lịch sử trước khi gỡ thư mục `tests/` theo yêu cầu người dùng. Repo hiện không còn suite test AI để chạy lại bằng pytest. Kiểm tra kết nối thật vẫn dùng các lệnh `python -m rag.dev ...` và `python -m rag.broker check` trong mã runtime, theo mục 6 hướng dẫn chính.

Các kết quả trong mục này mô tả lần kiểm tra trước khi chuyển trạng thái chỉ mục sang PostgreSQL.

## Dung lượng Docker và cache sau kiểm thử

Lần giải nén image vLLM làm ổ C gần đầy và Docker không ổn định. Cache pip cũ, khoảng 828 MB, vẫn nằm trong thư mục lưu trữ ngoài repo trên ổ D. Ổ C có lại khoảng 4,7 GB tại lần đo sau đó.

Trước khi build lại vLLM, cần đủ chỗ tại nơi Docker lưu disk image, không chỉ nơi đặt repo/model. Nên chuẩn bị khoảng 30–40 GB trống cho image/layers tạm, hoặc chuyển nơi lưu disk image Docker sang ổ D bằng chức năng chính thức của Docker Desktop. Chưa tự chuyển VHDX vì đó là dữ liệu Docker dùng chung với workload khác. Model 0.6B nằm trên D, nhưng điều đó không tự chuyển Docker layers khỏi C.

Docker Desktop đã được khôi phục sau lỗi dung lượng. Broker smoke `realestate-ai-smoke-rabbitmq-1` đã dừng thành công (exit 0); không xóa volume. Ổ C còn khoảng 4,6 GB ở lần đo cuối. Postman simulation đã dừng. Chưa tạo được container rerank; không có tiến trình model 4B/0.6B inference được để chạy nền.

## Quyết định RabbitMQ Cloud

Đã đổi cấu hình mặc định sang AMQPS cloud, gỡ broker local và dependency của worker khỏi Compose. `.env.example` chỉ cần `RABBITMQ_URL` do provider cấp, không ghép URL local hoặc dùng management API key. Các test broker local ở trên là bằng chứng kiểm thử lịch sử của logic messaging, không phải bằng chứng kết nối tài khoản cloud. Người dùng sẽ điền URL thật sau; chưa tạo instance hoặc gọi vào provider. Broker smoke cũ đã dừng, volume được giữ nguyên.

Kiểm tra sau chuyển cloud: Compose profiles `app`/`rerank` hợp lệ, không còn service/volume/dependency RabbitMQ local; Python AMQPS URL parsing, vhost percent-decoding và xác minh certificate/hostname đạt offline. `.env` thật không bị thay đổi, chưa kết nối tài khoản cloud.

## Rà soát file thừa

Đã bỏ `deploy/Dockerfile.vllm` chỉ bọc một dòng FROM; Compose dùng trực tiếp image chính thức `vllm/vllm-openai:v0.21.0`, tài liệu đổi lệnh build thành pull. Compose config đã kiểm tra hợp lệ.

Đã rà 15 đường dẫn artifact (model 4B bỏ dùng, cache pip dự phòng, archive uv, cấu hình broker smoke cũ, cache Python/pytest và log chatbot), tổng 8,91 GB / 8,30 GiB. Lệnh xóa trực tiếp bị automatic approval review chặn theo policy; các artifact này vẫn còn. Script `scripts/cleanup-chatbot-artifacts.ps1` đã chạy preview thành công; mặc định không xóa, người dùng có thể chạy với `-Apply`. Script dùng allowlist cố định và kiểm tra đường dẫn/link; giữ `.env` thật, model 0.6B, vector data, venv và công cụ uv đã giải nén.

## Gỡ scripts và tests khỏi repo

Theo yêu cầu người dùng, đã gỡ `real-estate-ai/scripts/` và `real-estate-ai/tests/` khỏi working tree. Lệnh xóa bị automatic approval review chặn theo policy; hai thư mục được chuyển nguyên vẹn sang `D:/RealEstateMobile-Project-backups/chatbot-scripts-tests-20261114-170554/`. Chưa xóa vật lý bản sao lưu. Script cleanup trước đó không còn trong repo; nội dung rà soát 8,91 GB ở trên là ghi nhận lịch sử, không phải hướng dẫn chạy script còn tồn tại.

Hướng dẫn tải model đã đổi sang Hugging Face CLI với revision cố định. Model 0.6B hiện có, `.env`, dữ liệu vector và các module runtime được giữ nguyên; backend Java tests nằm ngoài hai thư mục được yêu cầu gỡ.

Dependency Python đã được gom vào duy nhất `requirements.txt`, gồm cả Hugging Face CLI và pytest từ các file cũ; hướng dẫn cài đặt đã cập nhật. vLLM tiếp tục chạy trong image Linux riêng, không được thêm vào môi trường Python Windows.

## Gỡ Postman

Đã xác minh ứng dụng không tham chiếu `postman/` lúc runtime. Đã xóa 5 file gồm OpenAPI subset, mock config/handler và simulation config/context. Tài liệu đã bỏ lệnh chạy simulation và tham chiếu file không còn tồn tại; số đo kiểm thử cũ được giữ dưới dạng lịch sử. Lệnh xóa cây thư mục rỗng bị automatic approval review chặn theo policy, nên phần thư mục rỗng được chuyển ra ngoài repo vào thư mục backups. `real-estate-ai/postman/` không còn trong working tree.

## Dọn cấu hình .env

Đã rút `.env` và template về 19 biến chính cho Gemini, Qdrant Cloud, nguồn backend, rerank 0.6B local và RabbitMQ Cloud. Bỏ biến gateway `AI_*`, `INDEX_SOURCE_JSON` của profile mock và các tuning đang bằng mặc định; giữ các credential đang dùng, tạo secret nội bộ nếu thiếu. Không xoay key đã có hoặc in giá trị secret ra log. Các override tùy chọn vẫn được mã hỗ trợ khi cần thêm sau.

Qdrant localhost/collection mock đã được đổi sang cấu hình Cloud/dữ liệu backend với state riêng; dữ liệu index cũ không bị xóa. Rerank và publisher vẫn tắt đến khi nghiệm thu dịch vụ thật. Còn cần người dùng điền `GEMINI_LLM_MODEL`, `QDRANT_URL`, `QDRANT_API_KEY`, `RABBITMQ_URL`. Đọc cấu hình offline và Compose config đã kiểm tra hợp lệ; không gọi API/broker/Cloud trong lần dọn này. `.env` thật vẫn bị Git bỏ qua.
