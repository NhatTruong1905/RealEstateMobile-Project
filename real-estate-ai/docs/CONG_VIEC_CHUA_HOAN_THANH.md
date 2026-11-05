# Các việc chatbot AI chưa hoàn thành

Cập nhật: 04/11/2026. Phạm vi: `real-estate-ai`.

Đây là danh sách công việc còn lại, không phải xác nhận hệ thống đã chạy với dịch vụ thật. Theo yêu cầu người dùng, không tự chạy test AI. Các bước gọi Gemini thật bên dưới chỉ thực hiện khi người dùng xác nhận nhu cầu và ngân sách; không ghi API key vào tài liệu hoặc chat.

## 1. Dọn thư mục không dùng

- [ ] Xóa `real-estate-ai/tests`.
- [ ] Xóa `real-estate-ai/postman`.
- [ ] Sau khi xóa, cập nhật tài liệu còn hướng dẫn chạy pytest/Postman để tránh hiểu nhầm.
- [ ] Xem xét dọn `requirements-dev.txt` và `.pytest_cache` nếu không còn dùng công cụ test; không tự gỡ dependency khỏi virtualenv.

**Vướng mắc:** cơ chế xét duyệt tự động chặn lệnh xóa hai thư mục với lý do `blocked by policy`, kể cả khi chỉ định đường dẫn cố định. Hai thư mục vẫn còn tại thời điểm ghi tài liệu; cần người dùng xóa thủ công hoặc môi trường cho phép thao tác được yêu cầu.

**Đã chuẩn bị:** chuyển `listings_mock.json` và `rerank_eval_mock.json` từ `tests/fixtures` sang `data/`; cập nhật đường dẫn trong `.env`, `.env.example`, CLI chẩn đoán, benchmark và tài liệu. Giữ thư mục `data` vì nguồn seed đang dùng `./data/listings_mock.json`.

## 2. Hoàn tất cấu hình Gemini

- [ ] Người dùng xác nhận API key Gemini hợp lệ và project được phép sử dụng.
- [ ] Điền model khả dụng vào `GEMINI_LLM_MODEL` trong `.env`, thay placeholder nếu còn.
- [ ] Xác nhận quota và ngân sách dev cho LLM/embedding trong tài khoản Google.
- [ ] Khi người dùng cho phép gọi thật: xác nhận LLM, structured intent, streaming và embedding query/document hoạt động; ghi lại dimension và manifest tương thích.

**Hiện trạng:** `.env` đã được bổ sung các biến cần thiết, giữ giá trị key trước đó; chưa xác minh key/quota/model bằng API thật. Hướng dẫn thao tác nằm trong [SETUP_CHATBOT.md](SETUP_CHATBOT.md). Không yêu cầu đưa key cho agent.

## 3. Khởi động và cấu hình Qdrant thật

- [ ] Chốt Qdrant local qua Docker hoặc Qdrant Cloud theo lựa chọn người dùng.
- [ ] Nếu local: người dùng mở Docker Desktop, chờ Engine sẵn sàng; lần kiểm tra gần nhất daemon chưa chạy.
- [ ] Chọn và pin image/server version Qdrant, cấu hình volume bền vững và bind loopback cho local dev.
- [ ] Nếu Cloud: người dùng điền endpoint HTTPS và database API key vào `.env`.
- [ ] Khi người dùng muốn vận hành thật: xác nhận kết nối, collection, dimension và manifest tương thích; không tự xóa collection khi mismatch.
- [ ] Seed batch nhỏ sau khi Gemini và ngân sách sẵn sàng; chỉ cập nhật phần mới/thay đổi, không tự index hàng loạt lúc khởi động.
- [ ] Xác nhận child → parent và dữ liệu vẫn sử dụng được sau restart server; ghi server version và số parent/points thực tế.

**Hiện trạng:** có adapter Qdrant và SQLite lưu parent/mapping; chưa nghiệm thu Qdrant server thật. Collection dev cấu hình trong `.env.example` là `realestate_gemini_dev_v1_mock`, tách dữ liệu mẫu khỏi dữ liệu thật. Không nhập key Gemini vào Qdrant.

## 4. Nối nguồn tin đăng thật và chuyển dữ liệu

- [ ] Xây adapter đọc nguồn tin chuẩn từ backend, có ID/version và trạng thái được phép hiển thị hiện tại.
- [ ] Xác nhận quyền/trạng thái từ nguồn chuẩn trước khi đưa tin vào context; không chỉ tin payload cũ trong Qdrant.
- [ ] Chốt cơ chế sync thủ công cho nguồn thật, xử lý cập nhật/gỡ tin và bản ghi cũ mà không khôi phục tin đã gỡ.
- [ ] Xác nhận embedding contract và mapping FAISS cũ trước khi quyết định tái sử dụng vector hoặc re-index có giới hạn ngân sách.
- [ ] Chỉ chuyển sang collection thật khi dữ liệu và quyền xem đã được xác nhận; giữ index FAISS cũ cho đến khi có quyết định dọn riêng.
- [ ] Thiết lập backup/restore SQLite parent state cùng dữ liệu Qdrant.

**Giới hạn:** hiện chỉ nhận JSON `kind=mock`; không đổi nhãn dữ liệu thật thành mock để bỏ qua xác nhận quyền. Chưa triển khai Kafka; realtime không thuộc phần thiết lập hiện tại.

## 5. Thiết lập vLLM reranker local

- [ ] Chốt stack WSL/Linux, Python, PyTorch, CUDA và vLLM tương thích GPU/driver.
- [ ] Cài vLLM trong môi trường Linux riêng; không thêm vào virtualenv API Windows.
- [ ] Tải/pin model `Qwen/Qwen3-Reranker-0.6B`, revision và template/instruction đúng phiên bản runtime.
- [ ] Xác nhận server local hoạt động và API Windows truy cập được; không công khai reranker ra Internet.
- [ ] Chốt giới hạn context, concurrency và VRAM dựa trên khả năng phần cứng thực tế.
- [ ] Chỉ bật `RERANK_ENABLED=true` khi người dùng muốn sử dụng và runtime đã sẵn sàng.

**Hiện trạng gần nhất:** RTX 4050 Laptop, 6141 MiB VRAM, driver 560.94; chưa xác nhận vLLM/model chạy được hoặc đủ VRAM. Rerank đang mặc định tắt; giữ `false` trong lúc hoàn tất Gemini/Qdrant.

Đánh giá chất lượng/latency model thật chưa thực hiện. Theo yêu cầu hiện tại, không tự chạy benchmark hay test; nếu sau này cần số liệu thì thống nhất lại với người dùng trước.

## 6. Hoàn tất đưa chatbot vào sử dụng

- [ ] Sau khi Gemini/Qdrant/dữ liệu sẵn sàng, khởi động API theo cấu hình đã chốt.
- [ ] Người dùng xác nhận có muốn kiểm tra thủ công chat sync/stream với dịch vụ thật và chi phí liên quan.
- [ ] Cập nhật tài liệu bằng thông tin vận hành thực tế: model ID, dimension, versions, collection và giới hạn dữ liệu; không ghi secret.

Chưa tự commit, push hoặc deploy. Không đánh dấu hoàn tất hệ thống thật dựa trên kết quả mô phỏng trước đó.
