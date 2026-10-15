# Định hướng phát triển đồ án thành khóa luận

## 1. Tổng quan hiện trạng

Project hiện được tổ chức theo mô hình monorepo với ba thành phần chính:

- `real-estate-backend`: Spring Boot, Spring Security, JWT, JPA, Thymeleaf, WebSocket và PostgreSQL/MySQL.
- `real_estate_frontend`: ứng dụng Flutter phục vụ người mua, người bán và môi giới.
- `real-estate-ai`: FastAPI, LangChain, Gemini Embedding/LLM và FAISS để triển khai chatbot RAG.

Hệ thống hiện đã có những chức năng phù hợp với phạm vi đồ án ngành:

- Đăng ký, đăng nhập, Google/Facebook Login, OTP và JWT.
- Quản lý người dùng, vai trò và danh mục bất động sản.
- Đăng, duyệt, tìm kiếm và lưu tin bất động sản.
- Chat thời gian thực giữa khách hàng và người bán.
- Trang quản trị bằng Thymeleaf.
- Chatbot tư vấn bất động sản có streaming và lịch sử hội thoại.
- Triển khai backend, AI service, cơ sở dữ liệu và lưu trữ ảnh trên cloud.

Để phát triển thành khóa luận, mục tiêu không nên chỉ là bổ sung thêm nhiều màn hình hoặc chức năng. Hệ thống cần có một bài toán nghiên cứu rõ ràng, phương pháp đề xuất, dữ liệu thực nghiệm, phương pháp đối chứng và các chỉ số đánh giá định lượng.

## 2. Hướng khóa luận khuyến nghị

### 2.1. Tên đề tài gợi ý

> Xây dựng hệ thống tư vấn và gợi ý bất động sản hội thoại đa tiêu chí dựa trên truy hồi lai và RAG có kiểm chứng.

Một cách đặt tên khác:

> Nghiên cứu mô hình tìm kiếm và gợi ý bất động sản bằng ngôn ngữ tự nhiên kết hợp bộ lọc có cấu trúc, truy hồi ngữ nghĩa và mô hình ngôn ngữ lớn.

### 2.2. Bài toán nghiên cứu

Người dùng thường không tìm bất động sản bằng một từ khóa đơn lẻ mà mô tả nhu cầu dưới dạng hội thoại, ví dụ:

> Tôi cần căn hộ ở khu vực Thủ Đức, hai phòng ngủ, gần trường học, ngân sách tối đa ba tỷ và ưu tiên pháp lý rõ ràng.

Hệ thống cần đồng thời giải quyết các vấn đề:

1. Trích xuất đúng các tiêu chí từ tiếng Việt tự nhiên.
2. Duy trì tiêu chí qua nhiều lượt hội thoại và nhận biết khi người dùng đổi ý.
3. Lọc chính xác các ràng buộc cứng như giá, số phòng, trạng thái và vị trí.
4. Hiểu các yêu cầu mang tính ngữ nghĩa như yên tĩnh, thuận tiện cho gia đình hoặc gần tiện ích.
5. Xếp hạng và cá nhân hóa kết quả dựa trên hành vi người dùng.
6. Sinh câu trả lời có nguồn, có khả năng giải thích và hạn chế thông tin bịa đặt.

### 2.3. Đóng góp dự kiến

Khóa luận có thể tập trung vào bốn đóng góp chính:

- Đề xuất pipeline truy hồi lai kết hợp truy vấn dữ liệu có cấu trúc và tìm kiếm vector.
- Xây dựng cơ chế quản lý tiêu chí bất động sản qua hội thoại nhiều lượt.
- Xây dựng mô hình xếp hạng có giải thích dựa trên mức độ phù hợp và hành vi người dùng.
- Xây dựng bộ dữ liệu đánh giá tiếng Việt và thực nghiệm so sánh các phương pháp tìm kiếm.

## 3. Kiến trúc mục tiêu

```text
Flutter Mobile App
        |
        | HTTPS / WebSocket
        v
Spring Boot Core Backend
  - Authentication and Authorization
  - Property Management
  - Structured Search
  - Chat and Appointment
  - User Interaction Tracking
  - Recommendation API
        |
        | Internal authenticated API / events
        v
FastAPI AI Service
  - Intent and Constraint Extraction
  - Conversation State
  - Hybrid Retrieval
  - Re-ranking
  - Legal-document RAG
  - Citation and Answer Validation
        |
        +--> PostgreSQL/PostGIS
        +--> Vector Database
        +--> Object Storage
        +--> Monitoring and Evaluation Store
```

Nguyên tắc quan trọng là không đưa tất cả dữ liệu vào RAG:

| Loại dữ liệu | Cách xử lý phù hợp |
|---|---|
| Giá, diện tích, số phòng, trạng thái | Truy vấn có cấu trúc bằng SQL/Search API |
| Vị trí và khoảng cách | Truy vấn không gian bằng tọa độ/PostGIS |
| Tiêu đề và mô tả tin đăng | Tìm kiếm từ khóa kết hợp vector search |
| Luật, thủ tục và kiến thức pháp lý | RAG tài liệu có trích dẫn nguồn |
| Lượt xem, yêu thích, liên hệ | Mô hình gợi ý và xếp hạng cá nhân hóa |

Các điều kiện cứng phải được backend kiểm tra. LLM chỉ nên hỗ trợ hiểu nhu cầu, điều phối công cụ và diễn đạt câu trả lời.

## 4. Định hướng phát triển backend

### 4.1. Chuẩn hóa kiến trúc

Không cần tách ngay thành nhiều microservice. Trong phạm vi một khóa luận, nên duy trì Spring Boot dưới dạng modular monolith và tách AI thành một service riêng.

Có thể tổ chức backend theo nghiệp vụ:

```text
auth/
property/
search/
interaction/
chat/
appointment/
recommendation/
admin/
shared/
```

Mỗi module nên có API, application service, domain model và persistence rõ ràng. Việc này giảm phụ thuộc chéo và thuận lợi nếu cần tách service trong tương lai.

### 4.2. Nâng cấp cơ sở dữ liệu

- Chọn PostgreSQL làm cơ sở dữ liệu thống nhất cho phát triển và production.
- Sử dụng Flyway hoặc Liquibase thay cho việc chỉnh schema thủ công.
- Bổ sung latitude và longitude cho bất động sản.
- Cân nhắc PostGIS để tìm kiếm theo bán kính và tính khoảng cách.
- Tạo index cho trạng thái, giá, khu vực, loại hình, người đăng và ngày tạo.
- Bổ sung trường thời gian hết hạn, trạng thái kiểm duyệt và lý do từ chối tin.
- Không xóa cứng các bản ghi có giá trị lịch sử; sử dụng soft delete hoặc trạng thái lưu trữ khi phù hợp.

### 4.3. Search API

Xây dựng một Search API thống nhất hỗ trợ:

- Khoảng giá và khoảng diện tích.
- Loại giao dịch và loại bất động sản.
- Tỉnh/thành, quận/huyện, phường/xã.
- Số phòng ngủ, phòng vệ sinh, hướng và pháp lý.
- Tìm theo tọa độ hoặc bán kính.
- Phân trang, sắp xếp và nhiều chiến lược ranking.
- Chỉ trả về tin đã duyệt, còn hiệu lực và được phép hiển thị.

AI service phải gọi Search API này thay vì tự lọc toàn bộ dữ liệu bằng prompt hoặc biểu thức chính quy.

### 4.4. Đồng bộ dữ liệu với AI

Khi một tin được tạo, duyệt, chỉnh sửa hoặc ẩn, backend cần tạo sự kiện để AI cập nhật index. Có thể triển khai ban đầu bằng transactional outbox và một scheduled worker. Chỉ cân nhắc Kafka/RabbitMQ khi quy mô và yêu cầu thực nghiệm thực sự cần đến message broker.

Mỗi tài liệu trong vector database cần có metadata:

- `propertyId`.
- Phiên bản dữ liệu.
- Thời gian cập nhật.
- Trạng thái hiển thị.
- Loại giao dịch và khu vực.
- Hash nội dung để phát hiện thay đổi.

### 4.5. Chat và đặt lịch

- Lưu tin nhắn trên server thay vì xem dữ liệu local trên mobile là nguồn chính.
- Thiết kế conversation, participant, message, delivery status và read status.
- Xác thực JWT khi thiết lập kết nối WebSocket.
- Quản lý trạng thái đặt lịch bằng state machine: đề xuất, chờ xác nhận, đã xác nhận, hoàn thành, hủy.
- Bổ sung notification khi có tin nhắn hoặc thay đổi lịch hẹn.

### 4.6. Bảo mật

- Sử dụng access token ngắn hạn và refresh token có rotation/revocation.
- Kiểm tra quyền sở hữu khi sửa hoặc xóa bất động sản.
- Áp dụng method-level authorization cho các nghiệp vụ quan trọng.
- Giới hạn CORS theo domain thực tế, không dùng `*` ở production.
- Rate limit login, gửi OTP, tìm kiếm và AI chatbot.
- Quản lý secret bằng biến môi trường hoặc secret manager.
- Ghi audit log cho kiểm duyệt, thay đổi quyền và thao tác quản trị.
- Validate file upload, MIME type, dung lượng và quyền truy cập ảnh.

### 4.7. Chất lượng và vận hành

- Sinh tài liệu API bằng OpenAPI/Swagger.
- Thêm health check, metrics và structured logging.
- Gắn request ID/trace ID xuyên suốt backend và AI service.
- Dùng Testcontainers để kiểm thử tích hợp với PostgreSQL.
- Đo coverage nhưng ưu tiên test các luồng nghiệp vụ và bảo mật quan trọng.
- Thêm CI cho backend, Flutter và AI.
- Xây dựng Docker Compose cho môi trường phát triển cục bộ.

## 5. Định hướng phát triển frontend Flutter

### 5.1. Refactor cấu trúc

Frontend hiện có nhiều màn hình lớn và sử dụng `setState` ở nhiều nơi. Nên chuyển sang kiến trúc feature-first:

```text
lib/
  core/
    network/
    storage/
    routing/
    theme/
    widgets/
  features/
    auth/
    property/
    search/
    favorites/
    chat/
    appointment/
    recommendation/
    profile/
```

Trong mỗi feature có thể chia thành `data`, `domain` và `presentation`. Không bắt buộc áp dụng Clean Architecture máy móc; mục tiêu là tách UI khỏi API và nghiệp vụ.

### 5.2. Quản lý state và networking

- Chọn một giải pháp state management thống nhất như Riverpod hoặc Bloc.
- Xây dựng một HTTP client dùng chung với timeout, retry hợp lý và interceptor.
- Tự động gắn access token và xử lý refresh token.
- Chuẩn hóa `Result`, error model và thông báo lỗi.
- Hủy request khi người dùng rời màn hình hoặc thay đổi truy vấn.
- Debounce tìm kiếm và tránh gọi API lặp lại.

### 5.3. Lưu trữ cục bộ

- Token phải được lưu bằng secure storage.
- SharedPreferences chỉ dùng cho cài đặt nhỏ, không dùng làm database chat.
- Dùng SQLite/Drift/Isar nếu cần cache danh sách, hội thoại hoặc dữ liệu offline.
- Quy định rõ dữ liệu nào là cache và dữ liệu nào là nguồn sự thật từ server.

### 5.4. Trải nghiệm người dùng cho khóa luận

Các chức năng frontend nên phục vụ trực tiếp bài toán nghiên cứu:

- Ô tìm kiếm bằng ngôn ngữ tự nhiên.
- Hiển thị các bộ lọc AI đã hiểu để người dùng xác nhận hoặc chỉnh sửa.
- Kết quả dạng property card có điểm phù hợp và lý do đề xuất.
- Deep link từ câu trả lời chatbot đến trang chi tiết.
- So sánh từ hai đến bốn bất động sản.
- Bản đồ, tìm kiếm theo vùng và bán kính.
- Phản hồi “phù hợp/không phù hợp” cho từng đề xuất.
- Cho phép ẩn một kết quả và ghi nhận lý do.
- Hiển thị nguồn cho nội dung pháp lý.
- Cảnh báo rõ rằng thông tin AI chỉ mang tính tham khảo.

### 5.5. Accessibility và responsive

- Hỗ trợ tăng cỡ chữ và không cố định chiều cao cho vùng chứa văn bản.
- Đảm bảo độ tương phản màu.
- Kích thước vùng chạm phù hợp.
- Có semantic label cho icon và ảnh.
- Kiểm tra giao diện trên nhiều kích thước điện thoại và tablet.
- Hiển thị loading, empty, error và retry state đầy đủ.

### 5.6. Kiểm thử frontend

- Unit test DTO, formatter, validator, repository và state notifier/bloc.
- Widget test cho đăng nhập, tìm kiếm, bộ lọc, chi tiết và chatbot.
- Integration test cho luồng đăng tin, lưu tin, chat và đặt lịch.
- Golden test cho các component quan trọng nếu có thời gian.
- Thực hiện usability test với nhóm người dùng mục tiêu.

## 6. Định hướng phát triển AI chatbot

### 6.1. Pipeline đề xuất

```text
Câu hỏi người dùng
  -> Kiểm tra an toàn và phạm vi
  -> Phân loại intent
  -> Trích xuất tiêu chí có cấu trúc
  -> Kết hợp trạng thái hội thoại
  -> Gọi Structured Search API
  -> Keyword + Vector Retrieval
  -> Re-ranking ứng viên
  -> Sinh câu trả lời có cấu trúc
  -> Kiểm tra ràng buộc và citation
  -> Streaming về Flutter
```

### 6.2. Structured output

AI không nên chỉ trả về một chuỗi văn bản. Một response có thể có dạng:

```json
{
  "answer": "Các bất động sản dưới đây phù hợp với nhu cầu của bạn.",
  "filters": {
    "transactionType": "SALE",
    "districtIds": [2],
    "maxPrice": 3000000000,
    "bedrooms": 2
  },
  "properties": [
    {
      "id": 12,
      "score": 0.87,
      "reasons": [
        "Nằm trong ngân sách",
        "Đúng số phòng ngủ",
        "Gần khu vực yêu cầu"
      ]
    }
  ],
  "citations": [],
  "warnings": []
}
```

Flutter chịu trách nhiệm render property card từ dữ liệu backend. LLM không được tự tạo giá, địa chỉ hoặc ID bất động sản.

### 6.3. Hybrid retrieval

Thực nghiệm nên kết hợp:

- Bộ lọc SQL cho ràng buộc cứng.
- Keyword/BM25 search cho tên dự án và địa danh.
- Dense vector search cho nhu cầu ngữ nghĩa.
- Re-ranker để xếp lại các ứng viên cuối.

Có thể xây công thức điểm tổng hợp:

```text
finalScore =
    semanticScore * w1
  + keywordScore * w2
  + preferenceScore * w3
  + freshnessScore * w4
  + popularityScore * w5
```

Trọng số phải được điều chỉnh và đánh giá bằng thực nghiệm, không lựa chọn tùy ý mà không có số liệu.

### 6.4. Cá nhân hóa

Thu thập các tín hiệu:

- Xem chi tiết.
- Thời gian xem.
- Lưu hoặc bỏ lưu.
- Liên hệ người bán.
- Chấp nhận đặt lịch.
- Ẩn hoặc đánh giá không phù hợp.

Ở giai đoạn đầu có thể dùng content-based recommendation. Khi có đủ dữ liệu, bổ sung collaborative filtering hoặc learning-to-rank. Cần có chiến lược cold-start cho người dùng mới và tin đăng mới.

### 6.5. Legal RAG có kiểm chứng

- Tách kho tài liệu pháp lý khỏi kho tin đăng.
- Lưu tên văn bản, điều/khoản, ngày hiệu lực và URL nguồn trong metadata.
- Trả lời kèm citation.
- Không trả lời chắc chắn nếu không tìm thấy nguồn phù hợp.
- Hiển thị tuyên bố miễn trừ rằng chatbot không thay thế tư vấn pháp lý chuyên môn.
- Có quy trình cập nhật hoặc vô hiệu hóa tài liệu hết hiệu lực.

### 6.6. An toàn AI

- Chống prompt injection từ câu hỏi và nội dung tài liệu.
- Không để model tự quyết định quyền truy cập dữ liệu.
- Giới hạn độ dài input, history và output.
- Lọc dữ liệu cá nhân trước khi gửi đến nhà cung cấp LLM.
- Rate limit theo tài khoản/IP.
- Log phiên bản prompt, model, retriever và index để tái lập thí nghiệm.
- Không nạp file pickle/index từ nguồn không tin cậy.

## 7. Thiết kế thực nghiệm

### 7.1. Bộ dữ liệu đánh giá

Xây dựng khoảng 300–500 truy vấn tiếng Việt, chia thành các nhóm:

- Một tiêu chí và nhiều tiêu chí.
- Giá, diện tích, phòng ngủ, pháp lý và vị trí.
- Yêu cầu ngữ nghĩa như gần trường, yên tĩnh hoặc phù hợp gia đình.
- Hội thoại nhiều lượt và thay đổi nhu cầu.
- Không có bất động sản phù hợp.
- Câu hỏi ngoài phạm vi.
- Prompt injection và truy vấn gây nhiễu.
- Câu hỏi pháp lý cần nguồn.

Mỗi truy vấn tìm kiếm cần có danh sách kết quả đúng hoặc mức độ liên quan do người gán nhãn xác định.

### 7.2. Các baseline cần so sánh

1. SQL filter/keyword search truyền thống.
2. Dense vector RAG hiện tại.
3. Hybrid retrieval không có re-ranker.
4. Hybrid retrieval có re-ranker và bộ lọc ràng buộc.
5. Phương pháp đề xuất có thêm cá nhân hóa, nếu đủ dữ liệu.

### 7.3. Chỉ số đánh giá

#### Tìm kiếm và gợi ý

- Precision@K.
- Recall@K.
- MRR.
- nDCG@K.
- Tỷ lệ vi phạm ngân sách, vị trí, số phòng hoặc trạng thái.
- Coverage và diversity của đề xuất.

#### Sinh câu trả lời

- Faithfulness.
- Citation correctness.
- Tỷ lệ hallucination.
- Độ chính xác trích xuất intent và từng trường tiêu chí.
- Tỷ lệ từ chối đúng đối với câu hỏi ngoài phạm vi.

#### Hiệu năng

- Time to first token.
- Tổng thời gian phản hồi.
- Throughput và error rate.
- Chi phí trung bình trên mỗi truy vấn.

#### Trải nghiệm người dùng

- Task completion rate.
- Thời gian hoàn thành tác vụ.
- SUS hoặc thang Likert.
- Tỷ lệ click, lưu tin, liên hệ và đặt lịch.

### 7.4. Ablation study

Để chứng minh vai trò của từng thành phần, lần lượt loại bỏ:

- Bộ lọc có cấu trúc.
- Keyword retrieval.
- Vector retrieval.
- Re-ranker.
- Conversation state.
- Cá nhân hóa.

So sánh kết quả trước và sau khi loại bỏ giúp khóa luận giải thích được vì sao kiến trúc đề xuất hiệu quả.

## 8. Lộ trình triển khai gợi ý

### Giai đoạn 1: Chuẩn hóa nền tảng

- Hoàn thiện schema và migration.
- Refactor Flutter theo feature.
- Chuẩn hóa Search API, auth và error response.
- Thiết lập CI cho ba thành phần.

### Giai đoạn 2: Xây dữ liệu và baseline

- Làm sạch dữ liệu bất động sản.
- Bổ sung tọa độ và metadata.
- Xây bộ truy vấn đánh giá và gán nhãn.
- Đo SQL baseline và dense retrieval baseline.

### Giai đoạn 3: Phương pháp đề xuất

- Intent extraction và conversation state.
- Hybrid retrieval và re-ranking.
- Đồng bộ index tăng dần.
- Structured output, citation và guardrail.

### Giai đoạn 4: Cá nhân hóa và UI

- Thu thập interaction event.
- Xây scoring/recommendation.
- Hiển thị lý do đề xuất, bộ lọc AI và phản hồi người dùng.
- Hoàn thiện bản đồ, so sánh và đặt lịch.

### Giai đoạn 5: Thực nghiệm và viết báo cáo

- Chạy benchmark và ablation study.
- Kiểm thử tải, bảo mật và độ ổn định.
- Tổ chức usability test.
- Phân tích kết quả, giới hạn và hướng phát triển tiếp theo.

## 9. Phạm vi tối thiểu nên hoàn thành

Nếu thời gian hạn chế, phạm vi khóa luận tối thiểu nên gồm:

1. Search API có cấu trúc và dữ liệu đồng bộ.
2. Intent extraction cho tiếng Việt và hội thoại nhiều lượt.
3. Hybrid retrieval kết hợp SQL, keyword và vector.
4. Kết quả có giải thích và citation cho tài liệu pháp lý.
5. Bộ dữ liệu đánh giá cùng ít nhất ba baseline.
6. Flutter hiển thị filter, property card và feedback.
7. Báo cáo định lượng về độ chính xác, hallucination và latency.

Các tính năng như thanh toán, blockchain, VR/AR hoặc tách toàn bộ hệ thống thành microservices không nên được ưu tiên nếu chúng không phục vụ trực tiếp câu hỏi nghiên cứu.

## 10. Kết luận

Điểm mạnh hiện tại của project là đã có một hệ thống end-to-end hoạt động. Bước phát triển phù hợp nhất không phải viết lại toàn bộ mà là chuẩn hóa backend, tái cấu trúc Flutter và biến chatbot tĩnh thành một hệ thống tìm kiếm/gợi ý hội thoại có dữ liệu sống, có nguồn và có khả năng đánh giá.

Giá trị của khóa luận sẽ được quyết định chủ yếu bởi ba yếu tố:

- Bài toán nghiên cứu rõ ràng.
- Phương pháp đề xuất có lý do kỹ thuật.
- Kết quả thực nghiệm có thể đo lường và tái lập.
