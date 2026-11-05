# NHẬT KÝ THAY ĐỔI & TỐI ƯU HỆ THỐNG RAG (RAG SYSTEM CHANGE LOG)

## 💡 Tại sao Parent-Child lại là phương pháp tối ưu nhất cho RAG Bất động sản?

Trong các bài toán tra cứu BĐS, nếu dùng chunk quá to thì vector search không nhạy, nếu dùng chunk quá nhỏ thì thông tin bị đứt đoạn. Parent-Child giải quyết triệt để vấn đề này:

* **Child Chunks (Khối nhỏ ~250 ký tự)**:
  - Dùng để tính toán Embedding và lưu vào FAISS Vector Store.
  - **Ưu điểm**: Giúp Vector Search khớp cực kỳ chính xác các từ khóa chi tiết của người dùng như *"2 phòng ngủ"*, *"ngân sách 15 triệu"*, *"Quận 7"*, *"Sổ hồng"*.

* **Parent Chunks (Khối 1 căn BĐS ~600 ký tự)**:
  - Được lưu trong `docstore` (`InMemoryStore` trong RAM).
  - Khi Child Chunk được tìm thấy, `ParentDocumentRetriever` sẽ tự động tra ngược và lấy ra toàn bộ khối Parent hoàn chỉnh chứa đầy đủ thông tin của BĐS đó (Tên BĐS, Địa chỉ, Giá, Diện tích, Trạng thái, Mô tả).

👉 **Kết quả**: LLM luôn nhận được ngữ cảnh trọn vẹn của từng căn BĐS mà không sợ bị ngắt ngang hay mất thông tin tiêu đề.

---

### 1. Cơ Chế Lưu Vết & Tái Sử Dụng Vector Database Cục Bộ (Disk Persistence)
- Thêm cơ chế tự động kiểm tra và lưu Vector Store (FAISS index `index.faiss`) cùng dữ liệu parent docstore (`docstore.pkl`) vào thư mục `./vector_database`.
- **Lần đầu tiên khởi chạy**: Hệ thống tiến hành đọc file `.md`, phân mảnh và gọi embedding qua Ollama (chỉ tốn thời gian 1 lần duy nhất), sau đó tự động lưu kết quả ra thư mục `./vector_database`.
- **Các lần khởi chạy sau**: Hệ thống phát hiện dữ liệu đã có trên đĩa và nạp trực tiếp chỉ trong **vài miligiây** (siêu nhanh, không cần tính toán lại embedding).

### 2. Loại Bỏ SafeOllamaEmbeddings & Sử Dụng Trực Tiếp OllamaEmbeddings
- Đã gỡ bỏ lớp tùy chỉnh `SafeOllamaEmbeddings`.
- Sử dụng trực tiếp `OllamaEmbeddings(model="bge-m3")` tiêu chuẩn từ thư viện `langchain_ollama`.

### 3. Bộ Lọc Python Pre-Filtering Triệt Để 100% (Deterministic Python Filtering)
- Tích hợp hàm `format_and_filter_context` bằng Python trực tiếp trong Runnable Chain của LangChain trước khi truyền context vào LLM (`ChatOpenAI/Qwen2.5`).
- **Lọc Loại giao dịch (Bán vs. Cho thuê)**: Tự động phân tích ý định của câu hỏi. Nếu câu hỏi chứa từ khóa *"mua"*, Python loại bỏ 100% các BĐS Cho thuê khỏi context. Nếu chứa từ khóa *"thuê"*, loại bỏ 100% BĐS Bán.
- **Lọc Số phòng ngủ chính xác**: Nhận diện số phòng (ví dụ: *"2 phòng ngủ"*), Python chỉ giữ lại đúng các BĐS có đúng 2 phòng ngủ, loại bỏ hoàn toàn 1PN, 3PN, 4PN...
- **Lọc Trạng thái & Ngân sách**: Chỉ giữ các BĐS *"Đang mở bán"*, và lọc giá \(\le\) ngân sách nếu câu hỏi đề cập giá.
- **Khử trùng lặp**: Khử trùng lặp Property ID nếu có nhiều chunk trùng nhau.
- **Kết quả**: LLM chỉ nhận được danh sách BĐS đã qua lọc chuẩn 100%, triệt tiêu hoàn toàn khả năng mô hình tự ý đưa ra nhà cho thuê hay sai số phòng ngủ.




### 4. Loại Bỏ Hoàn Toàn Tất Cả Các Hàm Extract Theo Yêu Cầu (`rag/pipeline.py`)
- File [rag/pipeline.py](file:///d:/RealEstateMobile-Project/real-estate-ai/rag/pipeline.py) sử dụng kiến trúc RAG LangChain chuẩn 100%.

### 5. Cập Nhật Toàn Bộ Dữ Liệu 78 Bất Động Sản Chuẩn (`papers/hcm_properties_extended.md`)
- Toàn bộ 78 BĐS chuẩn từ `Property ID 1` đến `Property ID 78` đã được ghi đầy đủ vào file [papers/hcm_properties_extended.md](file:///d:/RealEstateMobile-Project/real-estate-ai/papers/hcm_properties_extended.md).

### 6. Tốc Độ & Streaming Realtime
- Dùng `ChatOpenAI(model="qwen2.5:3b", base_url="http://localhost:11434/v1", api_key="ollama", temperature=0.0)`.
- Hỗ trợ đầy đủ endpoint Streaming `/api/chat-rag/stream` cho frontend/mobile.


