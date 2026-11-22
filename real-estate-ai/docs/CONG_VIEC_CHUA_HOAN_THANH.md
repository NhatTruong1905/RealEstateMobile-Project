# Các việc chatbot AI còn cần hoàn tất

Cập nhật 14/11/2026. Cấu hình hiện hành: Gemini LLM/embedding, Qdrant Cloud, RabbitMQ Cloud và Qwen3-Reranker-0.6B/vLLM local. Hướng dẫn: [SETUP_FULL_STACK.md](SETUP_FULL_STACK.md); bằng chứng: [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md).

## 1. Phần đã có trong mã

- [x] Gemini adapters và HTTP rerank client hỗ trợ Bearer API key.
- [x] Qdrant parent/version state, đồng bộ upsert/delete, content hash và kiểm tra nguồn chuẩn.
- [x] Backend indexing outbox cùng transaction duyệt/sửa/gỡ; publisher confirms/returns.
- [x] AI worker, retry TTL, DLQ/redrive và snapshot/reconcile qua nguồn property backend.
- [x] Cấu hình RabbitMQ Cloud; Compose không chạy broker local.
- [x] Tải model 0.6B và cấu hình vLLM pooling/template local; serving chưa nghiệm thu.
- [x] Gỡ `scripts/`, `tests/`, `postman/` của service AI, gom dependency vào một `requirements.txt` và cập nhật hướng dẫn. Bằng chứng kiểm thử trước khi gỡ được giữ trong tài liệu trạng thái.

## 2. Người dùng điền tài khoản và cấu hình

- [ ] Gemini key/model khả dụng, quota/ngân sách; có thể tách key LLM và embedding.
- [ ] Qdrant Cloud endpoint và Database API key; collection/state riêng cho dữ liệu thật, không dùng hậu tố `_mock` cho nguồn backend.
- [ ] RabbitMQ Cloud AMQPS URL, vhost và quyền configure/write/read; xác minh hỗ trợ quorum/TTL/DLX theo gói dịch vụ.
- [ ] `PROPERTY_API_URL`, token chung backend/AI và các URL override nếu chạy ứng dụng bằng Compose.

Không đưa secret lên Git/chat. Không ghi đè `.env` thật trong lần cập nhật tài liệu này.

## 3. Nghiệm thu nguồn thật và Qdrant Cloud

- [ ] Áp dụng migration `004_property_index_*_forward.sql` đúng engine; xác minh profile backend và quyền API nội bộ.
- [ ] Chạy Gemini smoke có giới hạn ngân sách, xác nhận query/document dimensions và manifest.
- [ ] Sync batch nhỏ, tiếp tục bằng `next_after`; kiểm tra parent/points, restart và embedding contract trên Cloud thật.
- [ ] Chạy worker/publisher, kiểm tra duyệt mới, sửa, ẩn/xóa và sự kiện cũ không khôi phục tin đã gỡ.
- [ ] Kiểm tra mất kết nối broker/embedding/Qdrant, retry/DLQ/redrive và độ mới index trên tài khoản cloud thật.
- [ ] Thiết lập sao lưu và khôi phục trạng thái PostgreSQL cùng phiên bản với chỉ mục Qdrant.
- [ ] Xác minh dữ liệu FAISS cũ trước khi tái sử dụng hoặc dọn riêng; không tự re-index hàng loạt lúc khởi động API.

Các module đã có trong mã không thay cho việc nghiệm thu các bước này bằng dịch vụ thật.

## 4. Hoàn tất rerank local 0.6B

- [ ] Xử lý driver phù hợp image CUDA 13 đã chọn và dung lượng lưu Docker; không tắt kiểm tra CUDA.
- [ ] Xác nhận vLLM local lên được, template Qwen3 và endpoint `/v1/rerank` đúng.
- [ ] Chạy `python -m rag.dev rerank-check`; chỉ bật `RERANK_ENABLED=true` sau thành công.
- [ ] Đo tài nguyên/latency và chất lượng với truy vấn tiếng Việt đại diện; fallback không phải bằng chứng model đã chạy.

Model 0.6B đã tải; không cần tải 4B. Lần kiểm thử trước chưa chạy inference vì hạ tầng, xem trạng thái chi tiết trong tài liệu bàn giao.

## 5. Chuyển sang API rerank khi production

- [ ] Chọn provider và xác minh path/auth/request/response, quota, latency và dữ liệu được phép gửi.
- [ ] Đổi ba biến `RERANK_BASE_URL`, `RERANK_MODEL`, `RERANK_API_KEY`; nếu chạy Compose, đổi cả `RERANK_CONTAINER_BASE_URL`.
- [ ] Nếu khác contract Bearer + `/v1/rerank` + `results[index,relevance_score]`, bổ sung adapter trước khi bật.
- [ ] Smoke provider có kiểm soát chi phí, đánh giá chất lượng và restart/recreate API để nạp env mới.
- [ ] Khi chuyển hoàn toàn và không cần rollback: dừng/gỡ service vLLM, template `deploy/qwen3_reranker.jinja`, weights và cache liên quan.
- [ ] Giữ hoặc chuyển `deploy/property-event.schema.json` sang nơi quản lý contract; chỉ bỏ cả `deploy/` sau khi không còn tham chiếu.

Hiện chưa thực hiện chuyển API rerank. [Mục 7 của hướng dẫn](SETUP_FULL_STACK.md#7-chuyển-production) là quy trình chuẩn.

## 6. Đưa chatbot vào sử dụng

- [ ] Kiểm tra chat sync/text stream, dữ liệu được phép hiển thị và thông báo khi phụ thuộc lỗi.
- [ ] Xác minh auth/rate limit và các nhu cầu hội thoại/card/structured output trước khi public.
- [ ] Nếu đổi embedding contract production, tạo collection/state mới và re-index; đổi key đơn thuần không yêu cầu re-embed.
- [ ] Ghi versions, model IDs, dimension, latency/cost và giới hạn đã đo; chỉ đánh dấu sẵn sàng theo bằng chứng thật.

Chưa tự commit, push hoặc deploy. Không dùng số đo mock/local để tuyên bố Cloud hoặc model production đã đạt.
