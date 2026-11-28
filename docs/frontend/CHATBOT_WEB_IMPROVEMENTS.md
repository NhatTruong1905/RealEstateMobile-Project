# Chatbot AI và frontend web

Cập nhật ngày 24/11/2026. Phạm vi triển khai là FastAPI và frontend web. [Tài liệu chuyển sang Flutter](../handoffs/CHATBOT_MOBILE_HANDOFF.md) ghi lại hợp đồng và các ca cần kiểm tra khi quay lại mobile.

## Thay đổi

| Ưu tiên | Thay đổi đã triển khai |
|---|---|
| Lọc và hội thoại | Parse từng lượt của người dùng và áp dụng giá trị mới nhất. Hỗ trợ ngân sách ghép như *2 tỷ 500 triệu*, khoảng giá, loại giao dịch, quận, số phòng ngủ, diện tích và các cụm pháp lý phổ biến. Có các cụm bỏ tiêu chí và bắt đầu lại. Giá thuê cao vẫn được lọc theo ý định thuê. Điều kiện được áp dụng trên metadata đã được đối chiếu với backend. |
| Lỗi và stream | Lỗi nguồn Spring Boot đi ra dưới dạng lỗi dịch vụ. Web dùng `POST /api/chat-rag/v2/stream` và các event `delta`, `properties`, `done`, `error`. EOF thiếu `done` được báo là gián đoạn. Có nút dừng và thời hạn xử lý. Web chỉ lưu câu trả lời hoàn tất. Hai route cũ vẫn có sẵn cho mobile. |
| Thẻ và tham chiếu | Web hiển thị giá, diện tích, vị trí và liên kết chi tiết từ metadata nguồn chuẩn. Danh sách thẻ chỉ chứa ID vừa được tham chiếu trong câu trả lời và nằm trong ngữ cảnh đã kiểm tra. Câu *tin thứ 2* dùng thứ tự thẻ gần nhất, còn *mã tin 102* tra ID trực tiếp. Cả hai kiểm tra lại trạng thái công khai và phiên bản. |
| Truy xuất | Bật mặc định hợp nhất thứ hạng vector với điểm từ khóa BM25-style trong tập ứng viên đã hydrate. Nhánh lựa chọn `CHAT_POSTGRES_LEXICAL=true` truy xuất từ khóa độc lập trên PostgreSQL rồi hợp nhất với Qdrant bằng reciprocal rank fusion. Có SQL GIN index cho catalog lớn, chạy ngoài transaction. Rerank Qwen qua HTTP vẫn có fallback và đang tắt trong cấu hình thử. |
| API và vận hành | Có giới hạn form dữ liệu, CORS cấu hình qua env, `/healthz`, 60 yêu cầu/phút và tối đa 8 lượt đồng thời mỗi tiến trình theo mặc định. Có xác thực giữa gateway và FastAPI nếu đặt `CHAT_GATEWAY_TOKEN`; secret chỉ nằm ở server. |

### Biến cấu hình

| Tên | Mặc định / mục đích |
|---|---|
| `VITE_AI_BASE_URL` | `http://localhost:8000/api`. Khi deploy trỏ tới URL AI hoặc đường dẫn qua gateway, gồm tiền tố `/api`. |
| `CHAT_CORS_ORIGINS` | Danh sách origin phân tách bằng dấu phẩy. Đặt domain web chính xác nếu gọi khác origin. |
| `CHAT_LEXICAL_FUSION` | `true`. Tắt để đo riêng lọc cứng trên dense retrieval. |
| `CHAT_POSTGRES_LEXICAL` | `false`. Khi bật, dùng nhánh FTS độc lập thay cho bước BM25-style cục bộ. Áp dụng [SQL GIN index](../../real-estate-ai/deploy/postgres_lexical_index.sql) trước khi rollout trên catalog lớn. Không cần tạo lại vector. |
| `CHAT_REQUESTS_PER_MINUTE`, `CHAT_MAX_CONCURRENT_REQUESTS` | `60`, `8` mỗi worker FastAPI. Gateway public cần thêm quota theo người dùng hoặc IP, body size limit và giới hạn riêng cho kết nối dài. |
| `CHAT_GATEWAY_TOKEN` | Trống trong dev. Gateway tin cậy đặt header `X-Chat-Gateway-Token` sau bước kiểm tra quyền hoặc guest policy. Khi bật, cả API legacy cũng yêu cầu header. Kiểm tra client mobile đang phát hành trước khi đổi routing. |

Proxy SSE cần tắt buffering và cho phép request dài. `/healthz` xác nhận tiến trình đã qua startup, không dò lại mọi phụ thuộc trong mỗi lần gọi. Văn bản do Gemini tạo vẫn có thể sai; thẻ dùng metadata đã kiểm tra ngay lúc truy xuất và trang chi tiết cần kiểm tra lại quyền khi mở. Giới hạn hội thoại hiện là cửa sổ lịch sử client. Các trường hợp nhiều quận cùng lúc, phủ định phức tạp và ngôn ngữ ngoài mẫu cần bộ nhãn rộng hơn.

## Benchmark

Báo cáo dùng baseline từ commit `4a284be`. Phép đo offline giữ nguyên tập ứng viên và thứ tự dense để cô lập bộ lọc và xếp hạng. Phép đo live đọc snapshot tại thời điểm kiểm tra và gọi Gemini theo số truy vấn cố định.

### Dữ liệu kiểm soát

Fixture gồm 6 tin và các câu kiểm tra ngân sách, cập nhật tiêu chí, sai khu vực, sai số phòng, loại giao dịch, pháp lý, không có kết quả và ưu tiên từ khóa. Script chạy 100 lần mỗi truy vấn cho mỗi biến thể. `constraint_exact` đo khớp toàn bộ tập ID ở nhóm ràng buộc; nDCG@5 đo vị trí các tin đã gán nhãn. Với truy vấn không có kết quả, quy ước điểm 1 khi danh sách rỗng.

| Biến thể | Khớp toàn bộ ràng buộc | Recall@5 | nDCG@5 | p50 | p95 |
|---|---:|---:|---:|---:|---:|
| Baseline `4a284be` | 4/20 | 0,7222 | 0,6187 | 13,8 µs | 38,1 µs |
| Lọc cứng theo từng lượt | 20/20 | 1,0000 | 0,9484 | 55,6 µs | 102,8 µs |
| Lọc cứng + hợp nhất từ khóa | 20/20 | 1,0000 | 0,9692 | 96,0 µs | 211,7 µs |

Có 20 truy vấn ràng buộc và 4 truy vấn xếp hạng. Fixture ưu tiên các ca biên cần sửa, nên kết quả khớp 20/20 chỉ áp dụng cho bộ này. Độ trễ đo xử lý cục bộ trên 6 ứng viên, không bao gồm mạng, embedding hay sinh câu trả lời.

### Dữ liệu thật

Spring Boot local trả 75 bản ghi, có 20 tin công khai. API resolve trả đủ 75 bản ghi yêu cầu. PostgreSQL state có 20 parent công khai và 85 tombstone. Qdrant Cloud có 20 vector và manifest Cosine khớp `gemini-embedding-001`, dimension 3072. Gemini smoke chạy thành công với query embedding, document embedding, gọi chuẩn, structured intent và stream bằng `gemini-3.5-flash-lite`. SDK báo model dùng sampling mặc định, có log đóng SSL trên Windows sau smoke. Qdrant client 1.17.1 cảnh báo khi kết nối server 1.20.2.

| Truy vấn | Tin đúng | Precision@5 cũ → mới | Recall@5 cũ → mới | Delta đầu | Hoàn tất | Thẻ hợp lệ |
|---|---:|---:|---:|---:|---:|---:|
| Thuê ở Quận 7 | 2 | 40% → 100% | 100% → 100% | 3.925 ms | 4.415 ms | 2/2 |
| Mua ở Quận 1 | 2 | 40% → 100% | 100% → 100% | 4.170 ms | 4.479 ms | 2/2 |
| Thuê ở Thủ Đức | 3 | 60% → 100% | 100% → 100% | 4.521 ms | 5.646 ms | 3/3 |

Các nhãn live lấy từ loại giao dịch và quận trong snapshot nguồn công khai. Lần đo mỗi truy vấn chạy một stream. Embedding gọi riêng khoảng 845–960 ms. Cả ba biến thể mới đạt cùng Precision@5 và Recall@5 trong mẫu này. Chưa có bằng chứng nhánh độc lập tăng recall trên catalog thực lớn hoặc về p95 tải đồng thời. Cột latency chỉ mô tả luồng mới, chưa có đo latency end-to-end của bản cũ.

### Qwen3-Reranker-0.6B

Chạy weights chính thức revision `e61197ed45024b0ed8a2d74b80b4d909f1255473` trên Intel Core i7-13620H, float32, 4 thread, PyTorch 2.7.1+cpu và Transformers 4.57.6. Xếp hạng dựa trên chênh lệch logit `yes`/`no`. Phép đo dùng 4 truy vấn từ khóa của fixture, giữ nguyên từng tập 2–3 ứng viên đủ tiêu chí. [Model card Qwen](https://huggingface.co/Qwen/Qwen3-Reranker-0.6B)

| Truy vấn | nDCG@5 dense | nDCG@5 + từ khóa | nDCG@5 với Qwen | Inference Qwen |
|---|---:|---:|---:|---:|
| Ban công hướng sông | 0,6309 | 1,0000 | 0,5000 | 814,4 ms |
| Gần trường học | 0,5000 | 0,6309 | 0,6309 | 772,6 ms |
| Gần trung tâm | 1,0000 | 1,0000 | 1,0000 | 710,2 ms |
| Nội thất cao cấp | 0,6309 | 0,6309 | 0,6309 | 497,5 ms |
| Trung bình nDCG@5 | 0,6905 | 0,8155 | 0,6905 | |

Nạp model mất 2.070 ms. Trung vị inference mỗi batch là 741,4 ms, chưa gồm thời gian nạp model, tokenization hoặc HTTP. Trên fixture này, Qwen không cải thiện nDCG trung bình so với dense và kém phương án hợp nhất từ khóa, nên giữ rerank tắt. Docker Linux daemon không chạy trong lần rà soát, driver GPU là 560.94. Phép đo CPU chưa xác minh hiệu năng phục vụ qua vLLM hay cho một catalog lớn hơn.

## Nghiệm thu và các phần còn mở

- Live kiểm tra đọc từ Spring Boot, Gemini, Qdrant Cloud và PostgreSQL state thành công. RabbitMQ Cloud cho phép kiểm tra thụ động cả ba hàng đợi ứng dụng; tại thời điểm đo có 0 tin chờ và 0 consumer.
- Smoke RabbitMQ Cloud trên topology tạm, tách khỏi hàng đợi ứng dụng, kiểm tra thành công publisher confirms, manual ACK, retry TTL và sự kiện lỗi vào DLQ trong 2,02 giây. Cùng worker đã xử lý nguồn giả lập trả tombstone mới hơn một sự kiện cũ. Nghiệm thu còn lại trên staging gồm publisher Spring Boot, worker, cập nhật chỉ mục Qdrant thực tế theo thao tác duyệt/sửa/ẩn và redrive.
- Kiểm tra HTTP cục bộ dùng Spring Boot giả lập trả 503 qua socket thật. Đã kiểm tra phân biệt lỗi JSON 503, SSE lỗi sau delta, tương thích text stream, request 400/422, CORS, token gateway và 429.
- Edge headless đã chạy web thực, xác nhận thẻ từ truy vấn thuê Quận 7 và câu nối tiếp *tin thứ 2*. Kiểm tra stream bị ngắt và nút dừng dùng phản hồi kiểm soát. Build và lint web thành công; Vite còn cảnh báo kích cỡ bundle và lint báo một cảnh báo ngoài chatbot ở màn đăng tin.
- Các phần vận hành cần nghiệm thu tiếp gồm backup/restore đồng bộ giữa index và state, cảnh báo lag index, trace theo request, chi phí theo lưu lượng, và kiểm tra quyền trên gateway triển khai.
- Để nghiệm thu khóa luận đầy đủ, bổ sung bộ truy vấn tiếng Việt gán nhãn độc lập có tập phát triển và tập đánh giá, thử trên catalog lớn để đo Recall/nDCG và benchmark ANN so với exact. Phiên sở hữu trên server, cursor phân trang và dedup request giữa nhiều worker vẫn chưa triển khai.
