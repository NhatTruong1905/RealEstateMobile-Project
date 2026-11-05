# Chatbot Gemini + Qdrant + vLLM: bàn giao dev

Ngày kiểm tra: 04/11/2026. **Đã triển khai và kiểm thử phần mềm local; chưa đạt nghiệm thu toàn bộ hệ thống thật.**

Hướng dẫn bắt đầu và cấu trúc module sau refactor: [SETUP_CHATBOT.md](SETUP_CHATBOT.md).

## Cập nhật refactor 04/11/2026

- `pipeline.py` chỉ điều phối chat; tách provider, nguồn, embedding contract, retriever, bộ lọc, conversation, prompt, output và context thành file riêng. Giữ export tương thích và hai endpoint cũ.
- Thêm `python -m rag.dev setup-check`: kiểm tra offline, không gọi API hoặc in key; không coi cấu hình offline là nghiệm thu live.
- Dọn tài nguyên khi startup thất bại, kể cả store validate không đạt. Dependency FAISS chỉ import khi chọn profile FAISS.
- Kiểm tra cấu hình thực tế chỉ bằng trạng thái: key có giá trị nhưng chưa kiểm chứng; thiếu Gemini model và nguồn/collection mock. Không thay `.env` thật.
- Pipeline context đã chạy qua Postman simulation thật bằng HTTP: success đổi thứ tự `[2,1]` trong 62 ms; 503 giữ `[1,2]` trong 16 ms; delay 2500 ms giữ `[1,2]` sau deadline khoảng 1015 ms. Lần thử đầu qua `localhost` với deadline 1 giây bị timeout; lần xác nhận dùng loopback IPv4, deadline success 5 giây và lỗi 1 giây. Đây là evidence mô phỏng, không đo chất lượng model.
- Docker daemon vẫn chưa chạy; RTX 4050 Laptop 6141 MiB, driver 560.94. Không gọi Gemini tính phí, không tải/chạy weights vLLM, không di chuyển FAISS thật trong lượt refactor.
- Kiểm tra cuối sau refactor: `python -m pytest -q` đạt **47 passed, 3 warnings** (Pydantic cũ); `python -m pip check` không có dependency hỏng; `git diff --check` không có lỗi whitespace. Bảng 43 tests phía dưới là evidence trước refactor.

## Phạm vi đã thực hiện

- `rag/config.py`: profile Gemini trực tiếp cho trả lời và structured intent; chỉ chọn gateway bằng `LLM_PROVIDER=legacy`. Gemini không cần `AI_API_KEY` hay `AI_MODEL`. Model ID phải do người dùng xác minh, không có model mặc định được đoán.
- Giữ nguyên model embedding mặc định `models/gemini-embedding-001` và cách adapter xử lý query/document. Pin adapter 4.4.2. Collection có manifest model, dimension, task types, normalization, preprocessing, chunking và phiên bản adapter; mismatch dừng, không xóa collection.
- `rag/reranker.py`: một request `/v1/rerank`, documents là text, giới hạn độ dài, timeout gồm chờ semaphore, giới hạn concurrency. Kiểm tra đầy đủ số kết quả/index/score. Lỗi bất kỳ trả toàn bộ candidates theo thứ tự gốc. Không retry hoặc redirect. Log degraded chỉ chứa loại lỗi, số lượng, thời gian.
- Pipeline lọc giá/loại giao dịch và loại trùng trước rerank; giữ metadata/document gốc. Lời chào bỏ qua retrieval và rerank. Context/lịch sử/token đầu ra được giới hạn. Đường streaming chuyển tác vụ đồng bộ sang worker thread, giữ hai endpoint và schema cũ.
- `rag/qdrant_store.py`: child vector UUID ổn định; SQLite giữ toàn bộ parent, active point IDs, phiên bản/tombstone và manifest. Parent chỉ commit sau upsert thành công. Vectors mồ côi/cũ không thể vượt active-point check. Khởi động API chỉ nạp index, không tự gọi batch embedding.
- Sync thủ công có `limit`, `offset`, giới hạn chunk, báo upsert/delete/skipped/failed/remaining và exit code lỗi khi chỉ thành công một phần. Bản ghi không đổi/metadata-only không embed lại. Thiếu một bản ghi trong batch không đồng nghĩa xóa.
- Khi nguồn mock thay đổi public/version/content, retrieval kiểm tra lại nguồn trước context, loại dữ liệu cũ ngay cả trước sync. Không dùng payload Qdrant làm nguồn xác nhận quyền xem.
- Chỉ sửa service AI và tài liệu; không Kafka, frontend, commit, push hoặc deploy. Không sửa `.env` thật hay các file index FAISS cũ.

## Giới hạn dữ liệu quan trọng

Nguồn nghiệp vụ xác nhận quyền xem tin thật **chưa được nối**. Markdown hiện có gồm cả “Chờ duyệt” và “Từ chối”; không đủ để xác nhận quyền xem hiện tại. Bản này chỉ nhận JSON `kind=mock` và chỉ sync vào collection kết thúc `_mock`. Không đưa fixture vào collection thật.

Schema fixture nằm ở `data/listings_mock.json`: `id` chuỗi duy nhất, `version` nguyên dương, `public` boolean, `text`, `metadata`. Khi sửa nội dung, metadata hoặc public phải tăng version. Gỡ tin bằng bản ghi `public=false` với version cao hơn; giữ tombstone để replay cũ không khôi phục tin. SQLite và Qdrant phải được backup/restore cùng nhau.

Index chỉ cập nhật vào lần sync tiếp theo. Nếu không đọc được nguồn, tin bị gỡ hoặc nguồn khác version/hash với index, retrieval loại tin. Với dữ liệu thật cần adapter đọc nguồn chuẩn/kiểm tra quyền trực tiếp; không chỉ đổi `kind` thành mock cho dữ liệu thật.

Chưa di chuyển dữ liệu FAISS thật hoặc gọi Gemini re-index hàng loạt. Muốn tái sử dụng vector FAISS phải xác nhận dimension/task/preprocessing cùng mapping parent; chưa có manifest cũ đủ bằng chứng. Không tự giả định tương thích để nhập vào collection thật. Lựa chọn FAISS vẫn đọc index cũ nhưng cũng loại tin không xác minh được từ nguồn; vì vậy chưa thể dùng làm rollback dữ liệu thật đầy đủ.

## Chạy backend và kiểm thử

Chạy PowerShell trong thư mục `real-estate-ai`:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
.\.venv\Scripts\python.exe -m pytest -q
```

Mở `.env` local bằng editor, tham khảo `.env.example`, nhập `GOOGLE_API_KEY` và `GEMINI_LLM_MODEL` đã xác minh. Không ghi key vào chat, lệnh shell hoặc frontend. `.env` đã được xác nhận Git ignore. Chưa thay provider đang chạy trong `.env` của người dùng.

Sau khi tự xác nhận ngân sách dev, chạy smoke trước sync:

```powershell
.\.venv\Scripts\python.exe -m rag.dev gemini-smoke --allow-api-calls
.\.venv\Scripts\python.exe -m rag.dev sync --allow-api-calls --limit 3 --max-chunks 10
.\.venv\Scripts\python.exe -m rag.dev qdrant-check
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000
```

Smoke gọi query embedding, document embedding, LLM sync, structured intent và streaming; chỉ khi tất cả thành công mới ghi `vector_database/embedding-smoke.json`. Không in key, câu trả lời hay vector đầy đủ. Dimension thật lấy từ smoke, không mặc định 3072. Sync cần manifest phù hợp; API khởi động cần index đã seed. Khi nguồn lớn hơn limit, tăng `--offset` cho batch tiếp theo; không chạy lặp batch đầu rồi coi toàn bộ nguồn đã sync.

Lỗi smoke: script chỉ in loại exception để tránh lộ bí mật; kiểm tra model/key/quyền/quota trong console. Không có fallback gateway hoặc đổi embedding model ngầm. LLM đặt retry=0 và giới hạn output; embedding adapter giữ contract hiện hữu. Đây không phải cơ chế ngân sách chi tiêu cứng; vẫn phải theo dõi quota/billing bên Google.

Rollback riêng rerank: đặt `RERANK_ENABLED=false`, restart backend. Gemini vẫn được dùng. `VECTOR_STORE_PROVIDER=faiss` chọn index cũ nhưng không tự khôi phục quyền hiển thị tin thật. Gateway legacy cần cả `AI_BASE_URL`, `AI_API_KEY`, `AI_MODEL` do người dùng xác minh.

## Qdrant local và network

Máy có Docker CLI 29.8.2 nhưng daemon không hoạt động tại thời điểm kiểm tra; REST `127.0.0.1:6333` không kết nối được. Test hiện dùng **Qdrant embedded trên đĩa**, không phải Qdrant server Docker. Client đã pin `qdrant-client==1.17.1`; chưa có server tag/digest được smoke test, nên chưa cung cấp Compose với nhãn “đã kiểm chứng”.

Sau khi Docker Desktop chạy, kiểm tra `docker version`, cổng 6333 và container/volume hiện hữu. Chọn tag Qdrant tương thích, kiểm chứng bằng collection test và ghi digest trước khi coi cấu hình tái lập đã hoàn tất. Lệnh tham khảo, thay biến bằng image đã xác minh:

```powershell
# Set $QdrantDevImage to the exact verified qdrant/qdrant tag or digest first.
docker volume create realestate_qdrant_dev_data
docker run -d --name realestate-qdrant-dev -p 127.0.0.1:6333:6333 -v realestate_qdrant_dev_data:/qdrant/storage $QdrantDevImage
Invoke-RestMethod http://127.0.0.1:6333/collections
docker stop realestate-qdrant-dev
docker start realestate-qdrant-dev
```

Không xóa container/volume cũ để chạy lại. Native Windows dùng `QDRANT_URL=http://localhost:6333`. Nếu backend ở Docker, dùng service hostname trên cùng Docker network; localhost trong container không phải host. Qdrant không nhận Gemini API key. Chỉ bind loopback cho dev không auth.

Nguồn: [Qdrant Quickstart](https://qdrant.tech/documentation/quickstart/).

## vLLM local: phần còn thiếu

Đã đo: RTX 4050 Laptop GPU 6141 MiB, driver 560.94, `nvidia-smi` báo CUDA 12.6; WSL2 Ubuntu nhìn thấy GPU và dùng Python 3.14.4. Không thấy executable `vllm` trong Ubuntu; endpoint `127.0.0.1:8001/health` chưa truy cập được. Chưa tải weights, chưa chạy model, chưa xác nhận đủ VRAM. Không thay runtime/model tự động.

[Tài liệu GPU hiện hành](https://docs.vllm.ai/en/stable/getting_started/installation/gpu/index.html) yêu cầu Linux và có hướng WSL; cần chọn wheel/PyTorch/CUDA tương thích driver máy này trong environment Linux riêng. Không cài vLLM vào requirements API Windows. Trang stable được đối chiếu dẫn tới ví dụ v0.33.0; đó là phiên bản tài liệu tham khảo, **chưa phải pin đã smoke trên máy**.

Sau khi chọn được stack tương thích, pin vLLM/PyTorch/model revision và lấy score template từ cùng tag vLLM. [Ví dụ Qwen chính thức của vLLM](https://github.com/vllm-project/vllm/blob/v0.33.0/examples/pooling/score/qwen3_reranker_online.py) dùng `--runner pooling`, `--hf_overrides` và `--chat-template`; không chỉ kiểm tra HTTP 200. Lệnh tham khảo dưới đây cần đối chiếu lại với bản pin:

```bash
vllm serve Qwen/Qwen3-Reranker-0.6B \
  --runner pooling --host 127.0.0.1 --port 8001 \
  --hf_overrides '{"architectures":["Qwen3ForSequenceClassification"],"classifier_from_token":["no","yes"],"is_original_qwen3_reranker":true}' \
  --chat-template /path/to/pinned-vllm/examples/pooling/score/template/qwen3_reranker.jinja
```

Đo rồi mới đặt `max-model-len`, concurrency và GPU memory; chưa có giá trị đã benchmark cho 6 GB này. Kiểm tra `/health`, `/v1/models`, request `/v1/rerank` tiếng Việt có đúng/sai rõ ràng, đối chiếu thứ tự và template/instruction theo [model card Qwen](https://huggingface.co/Qwen/Qwen3-Reranker-0.6B). Native Windows thử localhost của WSL; nếu backend Docker, xác minh đường tới host riêng. Không mở reranker ra Internet. Dừng server foreground bằng Ctrl+C. Chỉ bật `RERANK_ENABLED=true` sau smoke đạt.

## Evidence đã chạy và phần chưa chạy

| Kiểm tra | Kết quả |
|---|---|
| `python -m pytest -q` | 43 passed, 4 warnings có sẵn từ Pydantic Field/FAISS dependency; khoảng 3.5 giây |
| `python -m pip check` | No broken requirements found |
| `git diff --check` | Không có lỗi whitespace |
| `python -m rag.dev --help` | CLI hoạt động |
| `python -m rag.dev sync` thiếu cờ API | Từ chối trước khi gọi API, đúng dự kiến |
| Qdrant embedded + fake embedding | Upsert, không trùng/không embed lại, metadata-only, đổi nội dung, xóa, replay cũ, restart, mismatch, source revoked và lỗi từng phần đạt |
| Fake Gemini trong pipeline/API | Sync/streaming/structured intent/history, Gemini không cần gateway, bảo vệ event loop đạt |
| HTTP mock transport | 4xx/5xx, timeout/connect, JSON lỗi, index âm/vượt/lặp/bool/float, score sai/NaN/Inf, thiếu kết quả đều fallback |
| HTTP socket local | Deadline và chờ concurrency đều bounded; đã sửa test deadline từ 100 ms lên 500 ms vì chi phí cold client trên Windows |
| Postman simulation HTTP thật | Success 63 ms, 503 fallback 31 ms, delay 2500 ms fallback ở 1000 ms; chỉ là số đo mô phỏng |
| Gemini API thật | Chưa chạy: chưa xác minh model/quota/ngân sách dev |
| Qdrant server restart | Chưa chạy: Docker daemon chưa sẵn sàng |
| vLLM/Qwen thật, VRAM, cold/warm | Chưa chạy: runtime/model chưa cài và chưa chốt stack tương thích |
| So sánh FAISS/Qdrant dữ liệu thật | Chưa chạy: thiếu manifest cũ và nguồn xác nhận quyền xem |
| nDCG@5 thật trên 20 câu | Chưa chạy; đã có runner + bộ nhãn synthetic dev để bắt đầu, cần tập dữ liệu đại diện thật |

Versions thực tế: Python Windows 3.10.11; `langchain-core 1.6.12`, `langchain-classic 1.0.8`, `langchain-google-genai 4.4.2`, `google-genai 2.31.0`, `qdrant-client 1.17.1`, `httpx 0.28.1`, `pytest 8.4.2`. Chưa có dimension thật, point/document count thật, model revision hay chi phí indexing đã đo. Không tuyên bố cải thiện chất lượng từ fake tests.

## Chạy lại mô phỏng và benchmark

Đã áp dụng [skill API Engineer](C:/Users/admin/.codex/plugins/cache/postman/postman/1.3.0/skills/api-engineer/SKILL.md), [API Simulation](C:/Users/admin/.codex/plugins/cache/postman/postman/1.3.0/skills/api-simulation/SKILL.md) và API Mocking cho kiểm thử local. CLI 1.75.0 có simulation nhưng `postman status` trả unknown command; không dùng cloud workspace hay upload. Mock được sinh từ subset OpenAPI bám tài liệu vLLM, scores là giả lập.

```powershell
postman simulation run postman/simulations/rerank.sim.yaml --port 4010 --no-history --output ndjson
```

Địa chỉ members: `http://localhost:4010/success`, `/unavailable`, `/slow`. Dùng `Reranker` với các base URL này và hai Document để kiểm tra mapping/fallback. Request log đã xác nhận POST tới success; injected error có thể không sinh event theo CLI. Dừng bằng Ctrl+C. Evidence có phạm vi trong `postman/simulations/rerank.context.yaml`.

Sau khi vLLM thật đạt smoke và bật rerank:

```powershell
.\.venv\Scripts\python.exe -m rag.benchmark
```

Runner dùng cùng candidates và bộ lọc cho OFF/ON, báo nDCG@5, request đầu, warm median và failed count; không gọi Gemini. Dataset `data/rerank_eval_mock.json` có 20 câu và 6 tin synthetic với nhãn thủ công, chưa đại diện đầy đủ cho dữ liệu thật. Bất kỳ response lỗi nào làm exit code khác 0, không tính fallback là kết quả model đạt. Thu thập thêm RAM/VRAM trong lúc chạy, ghi stack/revision và dùng nhãn được duyệt trước khi quyết định cấu hình cuối.
