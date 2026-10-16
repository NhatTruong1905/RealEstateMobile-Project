# RESEARCH AI CHATBOT

## 1. Mục tiêu nghiên cứu

AI Chatbot của hệ thống bất động sản được phát triển từ một RAG demo sử dụng dữ liệu Markdown và FAISS thành một hệ thống tìm kiếm, tư vấn và gợi ý bất động sản hội thoại theo kiến trúc Microservices.

Mục tiêu của hệ thống mới:

- Hiểu nhu cầu bất động sản bằng tiếng Việt tự nhiên.
- Duy trì tiêu chí qua nhiều lượt hội thoại và nhận biết khi người dùng thay đổi yêu cầu.
- Lọc chính xác các ràng buộc cứng như giá, vị trí, loại giao dịch, số phòng và trạng thái tin.
- Hiểu các tiêu chí ngữ nghĩa như yên tĩnh, phù hợp gia đình, gần tiện ích hoặc có tiềm năng đầu tư.
- Kết hợp tìm kiếm có cấu trúc, từ khóa và ngữ nghĩa.
- Xếp hạng lại kết quả theo mức độ phù hợp, sở thích người dùng và độ đa dạng.
- Sinh câu trả lời có căn cứ, không tự tạo giá, địa chỉ hoặc mã bất động sản.
- Hỗ trợ đo lường, tái lập thực nghiệm và so sánh nhiều phương pháp.

Tên hướng nghiên cứu đề xuất:

> Xây dựng hệ thống tìm kiếm và gợi ý bất động sản hội thoại dựa trên Microservices, truy hồi lai đa tầng và mô hình ngôn ngữ lớn triển khai cục bộ.

Phương pháp trung tâm có thể đặt tên:

> Adaptive Multi-stage Top-K Retrieval for Conversational Real Estate Search.

---

## 2. Hiện trạng AI Chatbot

Hệ thống hiện tại gồm:

- FastAPI cung cấp API chatbot.
- Gemini dùng cho sinh câu trả lời và embedding.
- FAISS lưu vector cục bộ.
- Parent-Child Retrieval.
- Dữ liệu bất động sản và địa điểm nằm trong các file Markdown.
- Một số bộ lọc giao dịch và ngân sách được thực hiện bằng Python/regex sau retrieval.
- Flutter gửi lịch sử hội thoại từ SharedPreferences lên AI Service.
- API chủ yếu trả về văn bản thuần.

Các hạn chế chính:

1. Dữ liệu Markdown/FAISS không phải nguồn dữ liệu nghiệp vụ thời gian thực.
2. Bộ lọc cứng được áp dụng sau retrieval nên có thể bỏ sót kết quả hợp lệ.
3. `k=25` hiện tại là 25 child chunks, không phải 25 bất động sản.
4. Một bất động sản có thể chiếm nhiều vị trí trong Top-K do có nhiều chunks.
5. Dữ liệu bất động sản và kiến thức địa điểm đang được đưa vào cùng một kho retrieval.
6. Chưa có re-ranker chuyên dụng.
7. Chưa có structured response để Flutter hiển thị filter, property card và lý do đề xuất.
8. Chưa có evaluation dataset và benchmark định lượng.
9. Việc nạp pickle với `allow_dangerous_deserialization=True` không phù hợp cho production.

---

## 3. Kiến trúc mục tiêu

```text
Flutter Mobile Application
        |
        v
API Gateway
        |
        +--> Authentication Service ------> PostgreSQL Auth DB
        |
        +--> Property/Search Service ------> PostgreSQL + PostGIS
        |
        +--> Conversation Service ---------> PostgreSQL + Redis
        |
        +--> Interaction/Recommendation ---> PostgreSQL Interaction DB
        |
        +--> AI Orchestrator Service
                |
                +--> vLLM Generation Service
                +--> vLLM Embedding Service
                +--> Re-ranker Service
                +--> Qdrant Vector Database
                +--> Property Search API
                +--> Recommendation API

Property Service
        |
        +--> Transactional Outbox
                |
                v
             RabbitMQ
                |
                v
        AI Indexing Worker
                |
                +--> Embedding Service
                +--> Qdrant
```

Nguyên tắc sở hữu dữ liệu:

- PostgreSQL là nguồn dữ liệu chính của nghiệp vụ bất động sản.
- PostGIS xử lý vị trí và khoảng cách địa lý.
- Qdrant chỉ là search index dẫn xuất, có thể xây dựng lại từ dữ liệu gốc.
- Redis lưu conversation state và cache ngắn hạn.
- RabbitMQ truyền sự kiện đồng bộ index.
- AI Service không được tự quyết định trạng thái, quyền truy cập hoặc dữ liệu chính thức của tin đăng.

---

## 4. LLM sinh câu trả lời

### 4.1. Lựa chọn

Mô hình đề xuất ban đầu:

```text
Primary generation model: Qwen3 8B hoặc model Qwen Instruct phù hợp phần cứng
Comparison model:         DeepSeek-R1 Distill 7B/8B
Inference engine:         vLLM
```

Qwen được ưu tiên cho chatbot chính vì hệ thống cần:

- Hội thoại tiếng Việt.
- Structured output.
- Tool calling.
- Tóm tắt kết quả ngắn gọn.
- Xử lý hội thoại nhiều lượt.
- Khả năng bật/tắt reasoning tùy loại tác vụ.

DeepSeek-R1 Distill phù hợp làm model đối chứng hoặc xử lý tác vụ suy luận phức tạp. Không nên dùng reasoning model cho mọi request vì có thể làm tăng latency, token và độ khó khi ép output JSON.

### 4.2. Nhiệm vụ của LLM

LLM chỉ thực hiện:

- Phân loại intent.
- Trích xuất tiêu chí có cấu trúc.
- Hợp nhất tiêu chí hội thoại.
- Lập kế hoạch gọi công cụ.
- Sinh câu trả lời từ dữ liệu đã được xác thực.
- Giải thích lý do đề xuất.

LLM không thực hiện:

- Tự lọc toàn bộ dữ liệu bằng prompt.
- Tự tạo giá, địa chỉ hoặc `propertyId`.
- Tự quyết định tin có được hiển thị hay không.
- Tự tính khoảng cách địa lý.
- Tự thực thi hành động thay đổi dữ liệu khi chưa được xác nhận.

### 4.3. Structured output

Ví dụ kết quả trích xuất:

```json
{
  "intent": "PROPERTY_SEARCH",
  "transactionType": "SALE",
  "propertyTypes": ["APARTMENT"],
  "districtIds": [7],
  "minPrice": null,
  "maxPrice": 3000000000,
  "minArea": 60,
  "maxArea": null,
  "bedrooms": 2,
  "bathrooms": null,
  "legal": ["SO_HONG"],
  "semanticPreferences": [
    "phù hợp gia đình có trẻ nhỏ",
    "gần trường học"
  ],
  "confidence": 0.94,
  "missingRequiredFields": []
}
```

Các intent dự kiến:

- `PROPERTY_SEARCH`
- `PROPERTY_DETAIL`
- `PROPERTY_COMPARE`
- `RECOMMENDATION`
- `LOCATION_ADVICE`
- `LEGAL_QUESTION`
- `MARKET_ANALYSIS`
- `SAVE_PROPERTY`
- `BOOK_APPOINTMENT`
- `OUT_OF_SCOPE`
- `GREETING`

Nếu confidence thấp hoặc thiếu tiêu chí quan trọng, chatbot cần hỏi lại thay vì tự suy đoán.

---

## 5. Embedding

### 5.1. Lựa chọn

Mô hình đề xuất:

```text
Baseline: Qwen/Qwen3-Embedding-0.6B
Nâng cao: Qwen/Qwen3-Embedding-4B
```

Không dùng model sinh văn bản thông thường như `Qwen3-4B` để tạo embedding. Phải dùng model được huấn luyện chuyên biệt cho embedding.

### 5.2. Chiến lược thực nghiệm

So sánh ít nhất:

1. Embedding hiện tại.
2. Qwen3-Embedding-0.6B.
3. Qwen3-Embedding-4B.
4. Một embedding model đa ngôn ngữ khác nếu có thời gian.

Chỉ số:

- Recall@K.
- MRR.
- nDCG@K.
- Latency embedding.
- Dung lượng vector.
- GPU/RAM sử dụng.

### 5.3. Quy tắc versioning

Mỗi vector phải lưu:

```json
{
  "embeddingModel": "Qwen/Qwen3-Embedding-0.6B",
  "embeddingVersion": "v1",
  "embeddingDimension": 1024,
  "contentHash": "...",
  "propertyVersion": 4
}
```

Không được:

- Embed document bằng model A và query bằng model B.
- Trộn nhiều số chiều trong cùng một vector field.
- Đổi model nhưng tiếp tục sử dụng index cũ.

Khi đổi model cần tạo collection mới, re-index, benchmark rồi đổi alias.

### 5.4. Field-aware chunking

Thay vì chỉ chunk theo số ký tự, dữ liệu property được chia theo trường:

```text
title
location
description
amenities
legal
```

Cần thực nghiệm:

- Fixed-size chunking.
- Parent-child chunking.
- Field-aware chunking.
- Semantic chunking.
- Một vector/property so với nhiều vector/property.

---

## 6. vLLM

vLLM được dùng như inference layer độc lập. Nên tách hai service:

```text
vLLM Generation Service
  - Sinh câu trả lời
  - Structured output
  - Tool calling

vLLM Embedding Service
  - Sinh dense vector
  - OpenAI-compatible /v1/embeddings
```

Kiến trúc triển khai:

```text
AI Orchestrator
    |
    +--> http://vllm-llm:8001/v1
    +--> http://vllm-embedding:8002/v1
```

Lợi ích:

- Scale generation và embedding độc lập.
- Đổi model không ảnh hưởng logic nghiệp vụ.
- Benchmark nhiều model dễ dàng.
- Restart embedding service không làm dừng chatbot.
- Có thể giới hạn concurrency và GPU riêng.

Nếu chỉ có một GPU:

- Ưu tiên VRAM cho LLM.
- Embedding theo batch khi có sự kiện thay đổi dữ liệu.
- Có thể chạy embedding bằng CPU/GPU khác.
- Không nhất thiết giữ embedding service tải cao liên tục.

Các cơ chế cần bổ sung:

- Request timeout.
- Concurrency limit.
- Queue.
- Health/readiness check.
- Model warm-up.
- Streaming.
- Request cancellation.
- Circuit breaker.
- Fallback model.

---

## 7. Qdrant Vector Database

### 7.1. Lý do lựa chọn

Qdrant phù hợp với kiến trúc Microservices vì:

- Là vector database độc lập.
- Hỗ trợ dense và sparse vector.
- Hỗ trợ metadata/payload filtering.
- Hỗ trợ hybrid query, RRF và DBSF.
- Có thể scale độc lập với PostgreSQL.
- Hỗ trợ collection alias và versioning.

### 7.2. Collection

Không trộn tất cả loại dữ liệu vào cùng collection:

```text
property_chunks_v1
legal_documents_v1
location_knowledge_v1
market_reports_v1
```

Sử dụng alias:

```text
property_chunks_current -> property_chunks_v1
```

Khi re-index:

```text
property_chunks_v2
  -> benchmark
  -> đổi alias
  -> giữ v1 để rollback
```

### 7.3. Point schema

```json
{
  "id": "property-125-description-0",
  "vector": {
    "dense": [],
    "sparse": {}
  },
  "payload": {
    "propertyId": 125,
    "parentId": "property-125",
    "chunkType": "description",
    "chunkIndex": 0,
    "content": "...",
    "propertyVersion": 4,
    "contentHash": "...",
    "transactionType": "SALE",
    "propertyTypeId": 2,
    "districtId": 7,
    "wardId": 15,
    "price": 2900000000,
    "area": 75,
    "bedrooms": 2,
    "legal": "SO_HONG",
    "status": "PUBLISHED",
    "embeddingModel": "Qwen/Qwen3-Embedding-0.6B",
    "embeddingVersion": "v1"
  }
}
```

Các payload field cần index:

- `propertyId`
- `status`
- `transactionType`
- `propertyTypeId`
- `districtId`
- `wardId`
- `price`
- `area`
- `bedrooms`
- `legal`
- `embeddingVersion`

### 7.4. Đồng bộ dữ liệu

Qdrant không phải nguồn dữ liệu chính. Luồng đồng bộ:

```text
Property Service ghi PostgreSQL
        |
        +--> ghi Outbox Event trong cùng transaction
                |
                v
             RabbitMQ
                |
                v
        AI Indexing Worker
                |
                +--> normalize
                +--> chunk
                +--> embedding
                +--> upsert/delete Qdrant
```

Sự kiện:

- `PROPERTY_PUBLISHED`
- `PROPERTY_UPDATED`
- `PROPERTY_UNPUBLISHED`
- `PROPERTY_DELETED`
- `PROPERTY_EXPIRED`

Worker cần:

- Idempotency.
- Retry với exponential backoff.
- Dead-letter queue.
- Event version.
- Content hash.
- Công cụ replay/rebuild index.

---

## 8. Hybrid Search

Hybrid Search đề xuất gồm nhiều nhánh:

```text
Structured SQL/PostGIS
+ BM25 Sparse Search
+ Dense Semantic Search
-> RRF/DBSF Fusion
-> Cross-encoder Re-ranking
-> Business/Personalization Scoring
-> MMR Diversity
```

### 8.1. Structured Search

PostgreSQL xử lý hard constraints:

- Giá.
- Diện tích.
- Số phòng.
- Loại giao dịch.
- Loại bất động sản.
- Quận/phường.
- Pháp lý bắt buộc.
- Trạng thái và thời hạn tin.

Hard constraints phải loại kết quả trước retrieval/ranking, không được biến thành điểm mềm.

### 8.2. Geo Search

PostGIS xử lý:

- `ST_DWithin`: lọc trong bán kính.
- `ST_Distance`: tính khoảng cách.
- K-nearest neighbor theo vị trí.
- Distance decay cho soft ranking.

LLM không được tự suy đoán khoảng cách.

### 8.3. BM25 Sparse Search

Phù hợp với:

- Tên dự án.
- Địa chỉ.
- Tên đường.
- Mã bất động sản.
- Pháp lý.
- Từ viết tắt như `Q7`, `2PN`, `SHR`.

Cần chuẩn hóa tiếng Việt:

- Lowercase.
- Unicode normalization.
- Bản có dấu và không dấu.
- Từ điển đồng nghĩa.
- Chuẩn hóa viết tắt.
- Vietnamese word segmentation nếu thực nghiệm chứng minh có lợi.

Ví dụ:

```text
2PN -> 2 phòng ngủ
Q7 -> Quận 7
SHR -> sổ hồng riêng
chung cư <-> căn hộ
```

### 8.4. Dense Semantic Search

Phù hợp với:

- Yên tĩnh.
- Phù hợp gia đình.
- Không gian xanh.
- Thuận tiện đi làm.
- Có tiềm năng đầu tư.
- Gần các tiện ích cần thiết.

Thuật toán:

```text
HNSW Approximate Nearest Neighbor
Cosine similarity
```

### 8.5. Fusion

Không cộng trực tiếp raw cosine score với raw BM25 score vì hai score nằm trên thang đo khác nhau.

Phương pháp mặc định:

```text
Reciprocal Rank Fusion - RRF
```

Công thức:

```text
RRF(d) = sum(1 / (k + rank_i(d)))
```

Thực nghiệm cần so sánh:

1. RRF.
2. Weighted RRF.
3. DBSF.

Khi chưa có dữ liệu gán nhãn, RRF là baseline an toàn. Khi đã có validation set, tune Weighted RRF và so sánh với DBSF bằng nDCG/MRR.

### 8.6. Intent-aware fusion

| Loại truy vấn | Dense | BM25 |
|---|---:|---:|
| Tên dự án/địa chỉ cụ thể | 0.6 | 1.5 |
| Yêu cầu ngữ nghĩa | 1.5 | 0.7 |
| Truy vấn hỗn hợp | 1.0 | 1.0 |
| Câu hỏi pháp lý | 1.0 | 1.2 |

Trọng số cuối cùng phải được lựa chọn bằng validation set.

---

## 9. Five-stage Adaptive Top-K

Hệ thống sử dụng năm tầng Top-K:

```text
K1: Retrieval Top-K
 -> K2: Fusion/Property Top-K
 -> K3: Re-ranking Top-K
 -> K4: Context Top-K
 -> K5: Output Top-K
```

### 9.1. K1 - Retrieval Top-K

Hai nhánh:

```text
dense_k = 100
sparse_k = 100
```

Adaptive expansion:

```text
Lần 1: dense=50,  sparse=50
Lần 2: dense=100, sparse=100
Lần 3: dense=200, sparse=150
```

Chỉ mở rộng nếu chưa đủ kết quả vượt relevance threshold.

### 9.2. K2 - Fusion/Property Top-K

```text
fusion_property_k = 50
```

Quy trình:

```text
Dense chunks + BM25 chunks
 -> RRF
 -> group theo propertyId
 -> khử trùng
 -> Top 50 properties
```

Mỗi property giữ tối đa hai chunks.

Aggregation khởi đầu:

```text
propertyScore = bestChunkScore + 0.1 * secondBestChunkScore
```

Cần so sánh:

- Max pooling.
- Mean pooling.
- Top-2 weighted pooling.
- Learned aggregation.

### 9.3. K3 - Re-ranking Top-K

```text
Cross-encoder nhận Top 50
-> giữ Top 10
```

Model đề xuất:

```text
Baseline: Qwen/Qwen3-Reranker-0.6B
Nâng cao: Qwen/Qwen3-Reranker-4B
```

Cross-encoder nhận đồng thời query đã tổng hợp và property document để tạo relevance score.

### 9.4. K4 - Context Top-K

```text
preferred_context_k = 5
minimum_context_k = 3
maximum_context_k = 7
```

K4 phụ thuộc token budget. Không đưa toàn bộ Top 50 vào LLM.

### 9.5. K5 - Output Top-K

```text
output_k = 5
```

Flutter hiển thị năm kết quả đầu tiên và hỗ trợ phân trang/xem thêm. Nếu chỉ có ba kết quả vượt threshold thì trả ba, không thêm kết quả kém để đủ năm.

### 9.6. Cấu hình tổng hợp

```yaml
top_k:
  retrieval:
    dense_k: 100
    sparse_k: 100

  fusion:
    algorithm: weighted_rrf
    property_k: 50
    max_chunks_per_property: 2

  reranker:
    input_k: 50
    output_k: 10

  context:
    preferred_k: 5
    minimum_k: 3
    maximum_k: 7
    token_budget: 3000

  output:
    page_size: 5
    maximum_k: 10
```

### 9.7. Adaptive Top-K

K được điều chỉnh theo:

- Intent.
- Số candidate sau SQL.
- Confidence của constraint extraction.
- Độ mơ hồ của query.
- Phân phối score.
- Token budget.
- Latency budget.
- GPU load.

Các mức phát triển:

1. Fixed K.
2. Intent-aware K.
3. Candidate-aware K.
4. Iterative expansion K.
5. Confidence-aware K.
6. Token/latency-budget-aware K.
7. Learned Top-K Policy.

---

## 10. Re-ranking và lựa chọn kết quả cuối

Pipeline:

```text
RRF Top 50
 -> Group/Deduplicate
 -> Cross-encoder Top 10
 -> Business/Personalization Scoring
 -> Near-duplicate Removal
 -> MMR Top 5
```

### 10.1. Cross-encoder

Cross-encoder trả lời câu hỏi:

> Property nào phù hợp nhất với toàn bộ nhu cầu hiện tại của người dùng?

Input query phải được tổng hợp từ conversation state, không chỉ dùng câu cuối cùng.

Ví dụ:

```text
Người dùng muốn mua căn hộ tại Quận 7,
ngân sách tối đa 3 tỷ, đúng 2 phòng ngủ,
ưu tiên gần trường học và phù hợp gia đình.
Yêu cầu hiện tại: ưu tiên căn gần trường hơn.
```

### 10.2. Constraint coverage

```text
coverageScore =
  tổng trọng số tiêu chí mềm đã đáp ứng
  / tổng trọng số tiêu chí mềm yêu cầu
```

Nếu dữ liệu không có, trạng thái phải là `UNKNOWN`, không tự coi là đạt.

### 10.3. Business và personalization score

Ví dụ công thức ban đầu:

```text
finalScore =
    0.65 * crossEncoderScore
  + 0.10 * preferenceScore
  + 0.08 * constraintCoverage
  + 0.06 * geoScore
  + 0.05 * freshnessScore
  + 0.03 * propertyQuality
  + 0.03 * sellerTrust
```

Chỉ tiêu chí mềm được tham gia công thức này. Hard constraints đã được loại trước đó.

### 10.4. Near-duplicate detection

Property được coi là gần trùng khi có nhiều tín hiệu giống nhau:

- Cùng dự án.
- Cùng địa chỉ.
- Giá chênh lệch rất nhỏ.
- Diện tích và số phòng giống nhau.
- Ảnh hoặc mô tả gần giống.
- Cosine similarity vượt ngưỡng được tune.

Khi trùng, ưu tiên tin:

- Cập nhật mới hơn.
- Dữ liệu đầy đủ hơn.
- Người đăng uy tín hơn.
- Có chất lượng ảnh tốt hơn.

### 10.5. MMR Diversity

MMR trả lời câu hỏi:

> Trong các kết quả phù hợp, chọn danh sách cuối vừa liên quan vừa không quá giống nhau.

Công thức:

```text
MMR(d) =
  lambda * relevance(d)
  - (1 - lambda) * maxSimilarity(d, selected)
```

Cấu hình khởi đầu:

```text
lambda = 0.75
```

Quy tắc phụ:

- Tối đa hai property cùng một dự án.
- Tối đa ba property cùng một phường.
- Không hiển thị hai tin gần như trùng nhau.

### 10.6. Learning-to-Rank

Khi đã thu thập đủ interaction, thay công thức thủ công bằng LambdaMART/XGBoost Ranking.

Feature:

- BM25 score/rank.
- Dense score/rank.
- RRF rank.
- Cross-encoder score.
- Constraint coverage.
- Giá so với ngân sách.
- Khoảng cách địa lý.
- Freshness.
- Property quality.
- Seller trust.
- User preference.

Label gợi ý:

```text
Không tương tác:       0
Click/xem chi tiết:    1
Xem lâu:               2
Lưu tin:               3
Liên hệ:               4
Đặt lịch:              5
Ẩn/không phù hợp:     -1
```

Pipeline nâng cao nhất:

```text
Dense + BM25
 -> RRF
 -> Cross-encoder
 -> LambdaMART
 -> MMR
```

---

## 11. Conversation State

Không để Flutter gửi lại toàn bộ lịch sử làm nguồn trạng thái duy nhất.

Các entity:

```text
Conversation
ConversationMessage
ConversationState
ConversationSummary
ToolExecution
```

State mẫu:

```json
{
  "conversationId": "conv-123",
  "userId": 25,
  "activeIntent": "PROPERTY_SEARCH",
  "constraints": {
    "transactionType": "SALE",
    "districtIds": [7],
    "maxPrice": 3000000000,
    "bedrooms": 2
  },
  "semanticPreferences": ["gần trường học"],
  "excludedPropertyIds": [12, 18],
  "shownPropertyIds": [21, 25, 27],
  "selectedPropertyIds": [21, 27]
}
```

Redis lưu state hoạt động; PostgreSQL lưu lịch sử lâu dài.

---

## 12. Structured API Response

AI Service không chỉ trả `answer: string`.

```json
{
  "conversationId": "conv-123",
  "messageId": "msg-456",
  "answer": "Tôi tìm thấy 5 căn phù hợp.",
  "intent": "PROPERTY_SEARCH",
  "understoodFilters": {
    "transactionType": "SALE",
    "districtIds": [7],
    "maxPrice": 3000000000,
    "bedrooms": 2
  },
  "properties": [
    {
      "id": 125,
      "score": 0.93,
      "reasons": [
        "Nằm trong ngân sách",
        "Đúng 2 phòng ngủ",
        "Cách trường học khoảng 700 m"
      ]
    }
  ],
  "citations": [],
  "warnings": [],
  "traceId": "..."
}
```

SSE events:

```text
conversation.started
intent.extracted
filters.updated
search.started
properties.retrieved
answer.delta
citations.completed
message.completed
error
```

---

## 13. Grounding và chống hallucination

Sau khi LLM sinh câu trả lời, validator kiểm tra:

- `propertyId` có tồn tại không.
- Property còn `PUBLISHED` không.
- Giá, địa chỉ và số phòng có khớp backend không.
- Kết quả có vượt hard constraints không.
- Property có nằm trong candidate set không.
- Citation có thực sự hỗ trợ phát biểu không.

Nếu sai:

```text
Reject
 -> regenerate tối đa một lần
 -> nếu vẫn sai, trả template response an toàn
```

Dữ liệu property trên Flutter phải lấy từ Property Service, không parse từ văn bản LLM.

---

## 14. An toàn và bảo mật AI

- Xác thực JWT tại Gateway.
- Service-to-service authentication.
- Qdrant và vLLM nằm trong private network.
- API key/TLS cho internal service.
- Rate limit theo user và IP.
- Giới hạn input, history, context và output.
- PII redaction.
- Allowlist tool.
- Nội dung retrieval được xem là untrusted data.
- Không thực thi instruction nằm trong document.
- Hành động đặt lịch/lưu tin phải được người dùng xác nhận.
- Audit log cho tool execution.
- Secret manager.
- Loại bỏ pickle và unsafe deserialization.

---

## 15. Observability và LLMOps

Mỗi request có `traceId` xuyên suốt:

```text
Flutter -> Gateway -> AI -> Property -> vLLM -> Qdrant -> Reranker
```

Theo dõi:

- Time to first token.
- Tổng latency.
- Intent extraction latency.
- Search latency.
- Qdrant latency.
- Reranker latency.
- Input/output tokens.
- GPU utilization.
- Queue length.
- Error rate.
- Empty-result rate.
- Constraint violation rate.
- Hallucination rate.

Log version:

- LLM model.
- Embedding model.
- Reranker model.
- Prompt version.
- Qdrant collection version.
- Retrieval parameters.
- Top-K configuration.
- Candidate IDs và scores.

Không log trực tiếp dữ liệu cá nhân nhạy cảm.

Stack đề xuất:

```text
OpenTelemetry
Prometheus
Grafana
Loki hoặc ELK
Tempo hoặc Jaeger
```

---

## 16. Evaluation Framework

### 16.1. Bộ dữ liệu

- 300-500 truy vấn độc lập.
- 100 hội thoại nhiều lượt.
- Truy vấn một và nhiều tiêu chí.
- Truy vấn ngữ nghĩa.
- Truy vấn không có kết quả.
- Câu hỏi ngoài phạm vi.
- Prompt injection.
- Câu hỏi pháp lý.
- Relevance judgments cho từng query-property.

### 16.2. Baseline

1. SQL filter.
2. BM25.
3. Dense vector.
4. SQL + BM25.
5. SQL + dense.
6. SQL + dense + BM25 + RRF.
7. Hybrid + cross-encoder.
8. Hybrid + cross-encoder + MMR.
9. Hybrid + cross-encoder + personalization.
10. Hybrid + cross-encoder + LambdaMART + MMR.

### 16.3. Metrics

Retrieval:

- Precision@K.
- Recall@K.
- MRR.
- nDCG@K.
- Constraint violation rate.
- Coverage.
- Diversity.

Generation:

- Faithfulness.
- Citation correctness.
- Hallucination rate.
- Intent accuracy.
- Field-level precision/recall/F1.

Hiệu năng:

- Time to first token.
- P50/P95 latency.
- Throughput.
- GPU/RAM usage.
- Context tokens.

Người dùng:

- Click-through rate.
- Favorite rate.
- Contact rate.
- Appointment rate.
- Task completion rate.
- SUS/usability score.

### 16.4. Top-K experiments

```text
dense_k  in {20, 50, 100, 150, 200}
sparse_k in {20, 50, 100, 150}
fusion_k in {20, 30, 50, 75, 100}
rerank_k in {10, 20, 30, 50, 100}
context_k in {3, 5, 7}
output_k in {5, 10}
```

Chọn K nhỏ nhất mà việc tăng K tiếp theo không cải thiện đáng kể Recall/nDCG nhưng làm tăng latency hoặc GPU cost.

### 16.5. Ablation study

Lần lượt loại bỏ:

- Structured filter.
- BM25.
- Dense retrieval.
- RRF.
- Cross-encoder.
- Conversation state.
- Personalization.
- MMR.
- Adaptive Top-K.

---

## 17. Lộ trình triển khai

### Giai đoạn 1 - Nền tảng

- Chuẩn hóa Search API.
- Chuyển dữ liệu thật sang PostgreSQL/PostGIS.
- Triển khai Qdrant.
- Triển khai vLLM Embedding Service.
- Thiết kế collection/payload/version.
- Xây bộ 100 truy vấn baseline đầu tiên.

### Giai đoạn 2 - Indexing

- Transactional Outbox.
- RabbitMQ.
- AI Indexing Worker.
- Idempotency, retry, DLQ.
- Collection alias và zero-downtime re-index.

### Giai đoạn 3 - Retrieval

- Structured filtering.
- BM25 sparse retrieval.
- Dense retrieval.
- RRF/DBSF.
- Group theo property.
- Five-stage Top-K.

### Giai đoạn 4 - Ranking

- Qwen3 Reranker.
- Constraint coverage.
- Business score.
- Near-duplicate detection.
- MMR.
- Benchmark và ablation.

### Giai đoạn 5 - Conversation và UI

- Conversation state trong Redis/PostgreSQL.
- Structured response.
- SSE events.
- Flutter filter chips.
- Property cards.
- Lý do đề xuất.
- Compare/map/feedback.

### Giai đoạn 6 - Nâng cao

- Recommendation Service.
- Personalization.
- LambdaMART Learning-to-Rank.
- Legal RAG.
- Location/POI Service.
- Agentic tools có xác nhận.
- Observability và security testing.

---

## 18. Cấu hình đề xuất ban đầu

```yaml
ai:
  generation:
    provider: vllm
    model: Qwen3-8B
    temperature: 0

  embedding:
    provider: vllm
    model: Qwen/Qwen3-Embedding-0.6B
    version: v1

  reranker:
    model: Qwen/Qwen3-Reranker-0.6B
    input_k: 50
    output_k: 10

  vector_database:
    provider: qdrant
    collection_alias: property_chunks_current

  retrieval:
    dense_k: 100
    sparse_k: 100
    fusion: weighted_rrf
    fusion_property_k: 50
    max_chunks_per_property: 2

  ranking:
    mmr_lambda: 0.75
    maximum_per_project: 2

  context:
    preferred_properties: 5
    minimum_properties: 3
    maximum_properties: 7
    token_budget: 3000

  output:
    page_size: 5
```

Các giá trị này là cấu hình khởi đầu. Giá trị cuối cùng phải được quyết định bằng dữ liệu benchmark.

---

## 19. Tài liệu tham khảo kỹ thuật

- Qdrant Hybrid Queries: <https://qdrant.tech/documentation/search/hybrid-queries/>
- Qdrant Filtering: <https://qdrant.tech/documentation/search/filtering/>
- Qdrant Full-text/BM25 Search: <https://qdrant.tech/documentation/search/text-search/full-text-search/>
- vLLM Embedding Usage: <https://docs.vllm.ai/en/latest/models/pooling_models/embed/>
- vLLM Pooling Models: <https://docs.vllm.ai/en/latest/models/pooling_models/>
- Qwen3 Embedding 0.6B: <https://huggingface.co/Qwen/Qwen3-Embedding-0.6B>
- Qwen3 Embedding 4B: <https://huggingface.co/Qwen/Qwen3-Embedding-4B>
- Qwen3 Reranker 0.6B: <https://huggingface.co/Qwen/Qwen3-Reranker-0.6B>
- Qwen3 Reranker 4B: <https://huggingface.co/Qwen/Qwen3-Reranker-4B>

---

## 20. Kết luận

Kiến trúc AI Chatbot mục tiêu không còn là một RAG chain đơn lẻ. Hệ thống được phát triển thành một pipeline nhiều tầng:

```text
Intent và Constraint Extraction
 -> Conversation State
 -> SQL/PostGIS Hard Filtering
 -> Dense + BM25 Retrieval
 -> RRF/DBSF Fusion
 -> Property Aggregation
 -> Cross-encoder Re-ranking
 -> Business/Personalization Scoring
 -> Deduplication
 -> MMR Diversity
 -> Token-budget Context Selection
 -> Grounded Generation
 -> Response Validation
 -> Structured Streaming to Flutter
```

Các thành phần tạo giá trị nghiên cứu chính gồm:

1. Hiểu tiêu chí bất động sản tiếng Việt qua hội thoại nhiều lượt.
2. Hybrid retrieval kết hợp structured, lexical, semantic và geospatial search.
3. Five-stage Adaptive Top-K.
4. Cross-encoder, Learning-to-Rank và diversity-aware result selection.
5. Event-driven vector indexing trên Qdrant.
6. Grounded generation, citation validation và chống hallucination.

Đây là phạm vi đủ rộng cho kiến trúc Microservices, đồng thời vẫn có thể chứng minh bằng baseline, benchmark, ablation study và đánh giá người dùng.
