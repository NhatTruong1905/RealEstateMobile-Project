# Kế hoạch dev: Gemini LLM + Gemini Embedding + vLLM reranker local

Ngày: 04/11/2026. Trạng thái: kế hoạch đã thống nhất hướng công nghệ, chưa triển khai.

## 1. Mục tiêu và quyết định

- LLM và embedding dùng Gemini API; key chỉ nằm ở backend.
- Rerank chạy local bằng vLLM, model khởi điểm `Qwen/Qwen3-Reranker-0.6B`.
- Ưu tiên chi phí dev, có giới hạn tài nguyên và fallback khi rerank không khả dụng.
- Giữ FAISS và Gemini embedding hiện tại trong phạm vi này. Không chuyển Qdrant, Kafka hay triển khai toàn bộ thiết kế chatbot mới.
- Không sử dụng OpenCode/9Router làm đường gọi mặc định cho profile Gemini mới.
- Các lựa chọn provider trong kế hoạch này thay thế đề xuất DeepSeek/SiliconFlow tại `docs/RESEARCH_AI_CHATBOT.md` cho profile dev này; các đề xuất nghiên cứu khác chưa được triển khai tự động.

## 2. Hướng dẫn cho agent thực hiện

Vai trò: Backend. Đọc đầy đủ `AGENTS.md` và `docs/agent-rules/BACKEND_RULES.md` trước khi sửa mã. Kiểm tra `git status`, branch, worktree và các hướng dẫn bổ sung áp dụng cho đường dẫn sửa.

Chỉ sửa dịch vụ `real-estate-ai` và tài liệu liên quan. Không thay đổi frontend, schema nghiệp vụ, quy trình duyệt tin/email. Giữ nguyên thay đổi của người dùng; để thay đổi UNSTAGED, không git add/commit/push/deploy. Không tạo worker khác nếu chưa cần và chưa xác minh kênh điều phối.

Không đọc/in key thật ra log hoặc báo cáo. Không ghi key vào kế hoạch, Git hoặc lệnh shell có lịch sử. Việc gọi API thật có tính phí phải nằm trong ngân sách dev được xác nhận; unit test dùng client giả.

## 3. Hiện trạng đã khảo sát

- `real-estate-ai/rag/pipeline.py`: LLM đang dùng `ChatOpenAI` qua `AI_BASE_URL`, `AI_API_KEY`, `AI_MODEL` với mặc định gateway 9Router.
- Embedding đang dùng `GoogleGenerativeAIEmbeddings`, `GOOGLE_API_KEY` và `models/gemini-embedding-001`.
- Retrieval dùng FAISS và `ParentDocumentRetriever`, index lưu tại `vector_database`.
- Điểm tích hợp dự kiến: `get_context_for_chain`, sau `self.retriever.invoke(sq)` và trước khi format context. Agent phải kiểm tra lại toàn bộ luồng lọc, format và streaming trước khi sửa.
- `requirements.txt` đã có `langchain-google-genai`; chưa có triển khai reranker chuyên dụng được xác nhận.
- Chưa xác minh GPU/VRAM, WSL2, CUDA và phiên bản vLLM trên máy. Không coi hạ tầng local đã sẵn sàng.

## 4. Luồng đích

```text
Câu hỏi + trạng thái hội thoại
  → Gemini trích xuất yêu cầu khi cần
  → Gemini embed câu truy vấn
  → FAISS / ParentDocumentRetriever
  → lọc điều kiện bắt buộc hiện có, gom và loại ứng viên trùng
  → vLLM /v1/rerank với query + nội dung ứng viên
  → ánh xạ index về document gốc, chọn top N
  → format context
  → Gemini tạo câu trả lời / stream
```

Nếu reranker timeout, lỗi hoặc trả dữ liệu không hợp lệ: dùng thứ tự retrieval đã qua cùng bộ lọc. Reranker không được đưa lại tin bị lọc, không sửa metadata hay coi relevance_score là xác suất. Chào hỏi và tập ứng viên rỗng không gọi rerank. Kiểm tra bộ lọc hiện tại có phụ thuộc formatter hay không; nếu có, tách phần lọc dùng chung trước rerank và kiểm thử bảo toàn hành vi.

## 5. Hạ tầng vLLM local

1. Kiểm tra GPU/VRAM, driver, WSL2 Ubuntu và `nvidia-smi` trong WSL nếu dùng NVIDIA. Chốt môi trường được vLLM hỗ trợ trước khi cài.
2. Dùng môi trường Python riêng trong WSL/Linux cho vLLM, không thêm vLLM vào requirements của API Windows. Pin phiên bản đã smoke test và ghi lại GPU, driver, Python, PyTorch, vLLM, model revision.
3. Tải model một lần và giữ cache. Có thể cần Internet khi cài/tải lần đầu; suy luận rerank sau đó chạy local.
4. Lệnh tham khảo từ tài liệu vLLM; kiểm tra lại với phiên bản được pin:

```bash
vllm serve Qwen/Qwen3-Reranker-0.6B \
  --host 127.0.0.1 \
  --port 8001 \
  --hf_overrides '{"architectures":["Qwen3ForSequenceClassification"],"classifier_from_token":["no","yes"],"is_original_qwen3_reranker":true}'
```

5. Giới hạn context, batch/concurrency và GPU memory theo phần cứng đã đo. Không mặc định vLLM sẽ vừa VRAM chỉ dựa trên dung lượng weights. Nếu chỉ có CPU hoặc GPU không phù hợp, báo blocker hạ tầng và đề xuất phương án; không tự thay model/runtime.
6. Xác minh `/health`, model ID và một request `/v1/rerank` thực tế. Kiểm tra đúng template/instruction của Qwen theo ví dụ chính thức cho phiên bản pin; endpoint trả 200 chưa chứng minh điểm xếp hạng đúng.
7. API chạy native Windows có thể thử truy cập WSL qua localhost. Nếu API chạy Docker, xác minh địa chỉ host phù hợp; localhost trong container không trỏ tới máy host. Chỉ đổi bind/network khi cần, không công khai reranker ra Internet.

## 6. Cấu hình đề xuất

Agent thêm cấu hình có validation và cập nhật `.env.example` (không sửa key trong `.env` thật):

```dotenv
LLM_PROVIDER=gemini
GOOGLE_API_KEY=REPLACE_LOCALLY
GEMINI_LLM_MODEL=REPLACE_WITH_VERIFIED_MODEL_ID
GEMINI_EMBEDDING_MODEL=models/gemini-embedding-001
RERANK_ENABLED=false
RERANK_BASE_URL=http://127.0.0.1:8001
RERANK_MODEL=Qwen/Qwen3-Reranker-0.6B
RERANK_CANDIDATE_LIMIT=20
RERANK_TOP_N=5
RERANK_TIMEOUT_SECONDS=5
```

- Đây là tên biến đề xuất; thống nhất với cấu trúc config thực tế, tránh hai nguồn cấu hình mâu thuẫn.
- Profile Gemini dùng `ChatGoogleGenerativeAI` hoặc adapter Gemini chính thức phù hợp dependency hiện hữu, cho cả LLM trả lời và LLM trích xuất intent. Bảo toàn structured output, sync và streaming.
- Chọn Gemini model ID thực sự khả dụng cho tài khoản, kiểm tra giá/quota và hỗ trợ structured output/streaming. Không đoán model ID hoặc hứa free tier.
- Profile Gemini không yêu cầu `AI_API_KEY`/`AI_MODEL`, không âm thầm fallback gateway khi thiếu key hay API lỗi. Nếu giữ profile legacy, phải chọn rõ bằng config.
- Mặc định tắt rerank để môi trường chưa có vLLM vẫn khởi động được; bật sau smoke test. Trạng thái bật nhưng service lỗi phải báo degraded rõ ràng trong log.
- 20 ứng viên, top 5 và timeout 5 giây là giá trị thử ban đầu, cần benchmark. Candidate limit áp dụng sau khi gom parent documents; không nhầm số child chunks với số tin.
- Giữ nguyên embedding contract hiện tại: model, dimension, preprocessing, query/document task type và normalization. Nếu phát hiện thay đổi không tương thích, dùng index riêng hoặc re-index có kế hoạch, không ghi đè index cũ.

## 7. Các bước triển khai

### A. Khảo sát và chuẩn bị

- Đọc pipeline, schemas, API routes, config, luồng streaming, cách lưu/nạp FAISS và test hiện có.
- Xác định vị trí gọi LLM trích xuất intent và tạo câu trả lời; liệt kê hành vi cần bảo toàn.
- Ghi nhận hiện trạng hạ tầng vLLM và chốt dependency/version trước khi tích hợp.

### B. Adapter Gemini LLM

- Thêm lựa chọn provider rõ ràng, thay đường gọi cho profile Gemini.
- Bảo toàn hợp đồng API, lịch sử hội thoại, schema intent và streaming.
- Không thay đổi embedding/index chỉ vì đổi LLM.

### C. Reranker client độc lập

- Tạo module riêng, ví dụ `rag/reranker.py`, với giao diện nhận query và danh sách documents, trả danh sách documents đã xếp.
- Gửi request đến `RERANK_BASE_URL + /v1/rerank`; tránh nối trùng `/v1`.
- Payload gồm `model`, `query`, `documents`, `top_n`; documents là text, không phải vector.
- Tạo nội dung chấm điểm có giới hạn độ dài, giữ các trường quan trọng như vị trí, giá, diện tích, pháp lý nếu dữ liệu có sẵn; giữ document/metadata gốc để trả kết quả.
- Kiểm tra response: index nguyên, trong phạm vi, không lặp; score là số hữu hạn; đủ kết quả theo top_n/tập đầu vào. Không chấp nhận response sai để loại nhầm tài liệu; fallback toàn bộ tập ứng viên theo thứ tự gốc khi response không hợp lệ.
- Chỉ một request rerank mỗi lượt tìm kiếm trong bản đầu, không retry tự động trong đường trả lời. Dùng HTTP client có timeout; không block event loop trong đường async/streaming.

### D. Tích hợp và tối ưu chi phí

- Lọc trước rerank, giới hạn ứng viên, lấy top N rồi format context.
- Giới hạn đồng thời rerank để không làm tràn VRAM; đo cả thời gian chờ hàng đợi trong deadline.
- Không embed lại khi khởi động nếu index tương thích đã có. Không thay đổi cơ chế indexing ngoài phần cần thiết cho task.
- Giới hạn context và lịch sử gửi Gemini. Không gọi rerank để xử lý lời chào.
- Bản đầu chưa bắt buộc cache rerank. Nếu thêm cache, key phải chứa query thực tế, model/revision, instruction/preprocessing và hash nội dung kèm thứ tự ứng viên; có giới hạn kích thước/TTL, không cache lỗi.
- Log thời gian retrieval/rerank/LLM, số ứng viên và lý do fallback; không log API key, nội dung hội thoại hay toàn bộ tin mặc định.

## 8. Kiểm thử và tiêu chí nghiệm thu

Unit/integration dùng fake Gemini và fake HTTP reranker, không đốt quota trong CI:

- Đúng ánh xạ index → document/metadata dù response đổi thứ tự; không mất ID nguồn.
- Bộ lọc bắt buộc không bị bỏ qua; duplicate không chiếm nhiều slot.
- Tập rỗng, một ứng viên, ít hơn top N và lời chào hoạt động đúng.
- Tắt rerank không gọi HTTP; bật rerank thì tích hợp ở đúng giai đoạn trước format context.
- Timeout, mất kết nối, 4xx/5xx, JSON lỗi, index âm/vượt phạm vi/lặp, score không hữu hạn và response thiếu kết quả đều fallback có kiểm soát.
- Sync và streaming vẫn tuân thủ API hiện có; structured intent và lịch sử không bị thay đổi ngoài chủ đích.
- Gemini profile không bắt buộc key gateway cũ và không fallback ngầm.

Smoke local với vLLM thật: bộ câu hỏi tiếng Việt có ứng viên đúng/sai rõ ràng; kiểm tra log scores và đối chiếu thứ tự, đo cold/warm latency, RAM/VRAM, không chỉ kiểm tra HTTP 200. Ghi cả trường hợp ranking chưa cải thiện.

Đánh giá ban đầu: tối thiểu 20 truy vấn đại diện có nhãn liên quan, so sánh rerank OFF/ON trên cùng tập ứng viên bằng nDCG@5 hoặc MRR và latency. Không dùng reranker thay kiểm tra giá/khu vực/quyền xem. Chọn cấu hình cuối theo kết quả và ngân sách, không mặc định 0.6B luôn đủ chất lượng.

Tiêu chí hoàn thành:

1. Profile Gemini gọi được LLM và embedding đúng config, index cũ tương thích được giữ nguyên.
2. vLLM local chấm điểm Qwen3 Reranker đúng cách; backend chọn đúng documents theo index.
3. Reranker lỗi không làm hỏng chat, không vượt bộ lọc và có log fallback.
4. Có hướng dẫn cài/chạy/dừng, cấu hình network Windows/WSL hoặc Docker và phiên bản đã kiểm chứng.
5. Báo cáo lệnh test thực tế cùng kết quả; tách rõ fake tests, vLLM smoke và Gemini smoke. Phần không chạy được ghi rõ lý do, không báo PASS.
6. Có số đo chất lượng/latency/tài nguyên, không tuyên bố cải thiện nếu chưa có bằng chứng.

## 9. File dự kiến và bàn giao

- Sửa `real-estate-ai/rag/pipeline.py`, `.env.example`, `requirements.txt` nếu cần dependency HTTP/test.
- Thêm module config/reranker, tests và hướng dẫn chạy local trong phạm vi `real-estate-ai` hoặc `docs`.
- Không sửa `vector_database` để commit, không thêm model weights/cache/virtualenv vào Git.
- Bàn giao: file thay đổi, config mới, lệnh chạy, versions, test evidence, benchmark, blockers và cách rollback bằng `RERANK_ENABLED=false` (chỉ tắt rerank, vẫn giữ Gemini LLM).
- Tuân thủ kênh handoff trong AGENTS.md nếu khả dụng và đã xác minh phiên Manager hiện tại; không dùng Task/Dispatch cũ, không coi gửi mailbox thành công là Manager đã review.

## 10. Nguồn kỹ thuật để agent đối chiếu

- vLLM scoring và Qwen3 Reranker overrides: https://docs.vllm.ai/en/stable/models/pooling_models/scoring/
- vLLM GPU/WSL: https://docs.vllm.ai/en/stable/getting_started/installation/gpu/index.html
- Qwen model card và cách chấm điểm chuẩn: https://huggingface.co/Qwen/Qwen3-Reranker-0.6B
- Gemini API: https://ai.google.dev/gemini-api/docs

Các lệnh trong kế hoạch là hướng dẫn, chưa chạy kiểm chứng trên máy hiện tại. Agent phải đối chiếu tài liệu với phiên bản được pin trước khi triển khai.

## 11. Người dùng chuẩn bị Gemini API key

### 11.1. Lấy key và kiểm tra quyền sử dụng

1. Mở https://aistudio.google.com/apikey và đăng nhập tài khoản Google.
2. Chọn tạo API key, chọn hoặc tạo Google Cloud project dành riêng cho dev theo giao diện hiện tại. Nếu đã có key dùng được, có thể dùng lại.
3. Một key Gemini có thể dùng cho cả LLM và embedding nếu project có quyền/quota cho hai model đã chọn; không cần tạo key rerank vì reranker chạy local.
4. Kiểm tra model khả dụng, quota và mục Usage/Billing của project. Free tier không được đảm bảo cho mọi model/tài khoản/vùng; nếu cần bật billing, người dùng tự xem giá và thao tác trong console. Không coi cảnh báo ngân sách là giới hạn chi tiêu cứng; backend vẫn cần giới hạn token, số request và retry.
5. Giữ các hạn chế API phù hợp theo hướng dẫn Google, không mở unrestricted chỉ để chữa lỗi. Với key không hợp lệ, kiểm tra project, quyền và loại key theo tài liệu hiện hành.

Nguồn: [Gemini API keys](https://ai.google.dev/gemini-api/docs/api-key), [pricing](https://ai.google.dev/gemini-api/docs/pricing), [rate limits](https://ai.google.dev/gemini-api/docs/rate-limits).

### 11.2. Đặt key ở backend

Mở `real-estate-ai/.env` bằng editor trên máy, cập nhật trực tiếp, không gửi key vào chat:

```dotenv
GOOGLE_API_KEY=<key Gemini của bạn, chỉ lưu local>
LLM_PROVIDER=gemini
GEMINI_LLM_MODEL=<model ID đã xác minh>
GEMINI_EMBEDDING_MODEL=models/gemini-embedding-001
```

Các biến provider/model mới chỉ có tác dụng sau khi agent triển khai config ở mục 6. Không đặt key vào Flutter, frontend, `.env.example` hay tài liệu. Agent xác minh `.env` được Git ignore mà không in nội dung file. Không tạo thêm `GEMINI_API_KEY` nếu ứng dụng đã thống nhất đọc `GOOGLE_API_KEY`.

### 11.3. Smoke test trước khi index hàng loạt

- Agent cung cấp script dùng chính config/client của ứng dụng: gọi LLM với một câu ngắn và embedding với một đoạn text ngắn. Chỉ báo model, thành công/thất bại, số chiều vector và lỗi đã loại bí mật; không in key/vector đầy đủ.
- Kiểm tra cả embedding cho query/document theo contract thực tế; lưu model, dimension, task type, normalization, preprocessing và revision cấu hình vào manifest.
- Lỗi 401/403: kiểm tra key/quyền/project; 429: kiểm tra quota/rate limit/billing và backoff có giới hạn; model không tồn tại: kiểm tra model ID. Không retry vô hạn và không đổi model embedding ngầm.
- Chỉ chạy batch indexing sau khi smoke test thành công. Giữ model embedding hiện có nếu tương thích; tài liệu Gemini hiện vẫn liệt kê `gemini-embedding-001` cho text, không tự nâng lên model mới chỉ vì xuất hiện trong ví dụ.

Nguồn: [Gemini embeddings](https://ai.google.dev/gemini-api/docs/embeddings).

## 12. Hướng dẫn chuẩn bị Qdrant

**Phạm vi:** mục này bổ sung hướng dẫn hạ tầng theo yêu cầu người dùng. Profile triển khai ban đầu vẫn giữ FAISS ở mục 1. Việc bật Qdrant trong ứng dụng là giai đoạn riêng theo mục 13; khởi động Qdrant không tự chuyển dữ liệu FAISS. Qdrant lưu/tìm vector, không thay Gemini embedding và không cần nhận Gemini API key.

### 12.1. Phương án khuyến nghị cho dev: Docker local

1. Cài Docker Desktop, bật WSL2 backend nếu chạy Windows và khởi động Docker Desktop.
2. Mở PowerShell, kiểm tra `docker version`. Nếu daemon chưa sẵn sàng, xử lý Docker trước.
3. Kiểm tra cổng 6333 và container tên `realestate-qdrant-dev` chưa bị dùng. Không xóa container/volume đang có để chạy lại lệnh.
4. Chạy từng lệnh dưới đây. Named volume giữ dữ liệu khi container dừng; không dùng lệnh xóa volume nếu muốn giữ index:

```powershell
docker volume create realestate_qdrant_dev_data
docker run -d --name realestate-qdrant-dev -p 127.0.0.1:6333:6333 -v realestate_qdrant_dev_data:/qdrant/storage qdrant/qdrant
```

Image không có tag chỉ dùng để bắt đầu theo quickstart. Agent phải pin tag/digest thực tế đã kiểm chứng trong hướng dẫn/Compose trước khi bàn giao cấu hình tái lập được. Không tự pull image mới cho container dữ liệu cũ mà chưa kiểm tra tương thích.

5. Mở dashboard tại http://localhost:6333/dashboard. Kiểm tra API bằng PowerShell:

```powershell
Invoke-RestMethod -Uri 'http://localhost:6333/collections'
```

6. Local profile trên chỉ bind loopback và chưa bật auth, vì vậy **không cần Qdrant API key**. Không mở cổng ra mạng ngoài; nếu cần truy cập từ máy khác, thiết lập auth/TLS theo tài liệu trước.
7. Cấu hình backend cho giai đoạn Qdrant:

```dotenv
VECTOR_STORE_PROVIDER=qdrant
QDRANT_URL=http://localhost:6333
QDRANT_API_KEY=
QDRANT_COLLECTION=realestate_gemini_dev_v1
```

Các biến này chưa tồn tại tự động trong mã hiện tại; agent phải triển khai adapter/config ở giai đoạn 13. REST cổng 6333 đủ cho bản đầu, chưa cần publish gRPC 6334. Nếu backend chạy trong Docker, dùng hostname service trên cùng Docker network thay localhost; không đổi bind ra toàn mạng chỉ để tránh cấu hình network.

Quản lý container (không xóa dữ liệu):

```powershell
docker stop realestate-qdrant-dev
docker start realestate-qdrant-dev
docker logs --tail 100 realestate-qdrant-dev
```

Nguồn: [Qdrant Local Quickstart](https://qdrant.tech/documentation/quickstart/).

### 12.2. Phương án khác: Qdrant Cloud

1. Đăng nhập https://cloud.qdrant.io/.
2. Tạo cluster dev; nếu tài khoản có tùy chọn free tier, kiểm tra giới hạn hiện tại trước khi chọn. Người dùng tự chọn vùng/gói và phê duyệt chi phí trên console.
3. Khi cluster sẵn sàng, sao chép cluster endpoint HTTPS và tạo database API key có quyền phù hợp. Đây là key riêng của Qdrant, không phải key Gemini và không phải management key dùng để quản lý hạ tầng Cloud.
4. Điền local `.env`: `QDRANT_URL=<cluster endpoint>`, `QDRANT_API_KEY=<database key>`, `QDRANT_COLLECTION=realestate_gemini_dev_v1`.
5. Agent dùng Qdrant client lấy danh sách collections để kiểm tra kết nối; không in key. Lỗi auth thì kiểm tra database key/quyền; lỗi kết nối thì kiểm tra endpoint, TLS và trạng thái cluster.
6. Theo dõi dung lượng/quota và chi phí trong console. Dùng Cloud thì không cần chạy container Qdrant local.

Nguồn: [Qdrant Cloud Quickstart](https://qdrant.tech/documentation/cloud-quickstart/).

## 13. Giai đoạn riêng nếu chuyển FAISS sang Qdrant

Không thực hiện chỉ vì người dùng đã điền QDRANT_URL; agent phải xác nhận task được giao bao gồm chuyển vector store. Không cần chờ Qdrant để hoàn thành Gemini + rerank trên FAISS.

1. Thêm `VECTOR_STORE_PROVIDER=faiss|qdrant`, mặc định giữ FAISS, thêm dependency Qdrant tương thích và adapter độc lập.
2. Đo dimension từ embedding smoke thực tế, tạo collection mới với distance/normalization phù hợp contract. Nếu collection đã tồn tại, so sánh schema/manifest; mismatch phải dừng, không xóa/tạo lại ngầm.
3. Giữ mapping child → parent của ParentDocumentRetriever và lưu parent documents bền vững; chỉ chuyển child vectors sang Qdrant mà mất parent docstore sẽ làm retrieval lỗi sau restart.
4. Point ID dùng UUID hoặc uint64 hợp lệ; dùng ID ổn định, content hash/version để upsert idempotent, không chèn trùng khi chạy lại. Lưu metadata nguồn và trạng thái cần cho lọc.
5. Ưu tiên tái sử dụng vectors hiện có nếu xuất được cùng mapping/contract và kiểm chứng đầy đủ. Nếu không, re-index vào collection mới từ nguồn chuẩn với batch/quota/budget giới hạn; không gọi lại Gemini cho toàn bộ dữ liệu một cách ngầm định.
6. Smoke upsert/query trên collection test riêng, kiểm tra mapping metadata, bộ lọc, restart vẫn retrieval được và reranker nhận đúng documents.
7. So sánh FAISS/Qdrant trên cùng bộ truy vấn, kiểm tra không rò tin không được phép xem và có cơ chế cập nhật/xóa index nhất quán với nguồn. Chỉ bật provider Qdrant sau khi kiểm tra đạt; giữ dữ liệu FAISS để rollback.
8. Bàn giao phiên bản client/server, dimension, collection, manifest, số documents/points, lệnh test và chi phí indexing đã đo. Không ghi model weights, database volume, snapshot hoặc secrets vào Git.

Checklist người dùng chuẩn bị: Gemini API key local; model/quota/budget phù hợp; chọn Qdrant local hoặc Cloud nếu triển khai giai đoạn chuyển đổi; thông tin GPU/VRAM cho vLLM. Các phần hạ tầng/tài khoản chưa xác minh phải báo rõ, không đánh dấu sẵn sàng chỉ dựa vào file cấu hình.
