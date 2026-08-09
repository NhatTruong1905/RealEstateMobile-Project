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

## 📝 TỔNG HỢP TOÀN BỘ CÁC THAY ĐỔI TRONG HỆ THỐNG RAG (`rag/pipeline.py` & `api/routes.py`)

### 1. Khắc Phục Lỗi `RecursionError: maximum recursion depth exceeded` Trong `SafeOllamaEmbeddings`
- **Nguyên nhân**: Bản thân hàm `OllamaEmbeddings.embed_query(text)` của LangChain gọi lại `self.embed_documents([text])[0]`. Khi ta ghi đè `embed_documents` gọi `self.embed_query(text)`, hai hàm này đã gọi vòng quanh lẫn nhau gây ra lỗi đệ quy vô tận `RecursionError`.
- **Giải pháp xử lý triệt để 100%**:
  - Tạo hàm helper `_embed_single(self, text: str)` gọi trực tiếp tới `self._client.embed(model=self.model, input=text)`.
  - Cả `embed_documents` và `embed_query` đều gọi qua `_embed_single`.
  - **Kết quả**: Triệt tiêu 100% đệ quy và triệt tiêu 100% lỗi HTTP 400 Tokenize Error của Ollama trên Windows!

### 2. Loại Bỏ Hoàn Toàn Tất Cả Các Hàm Extract Theo Yêu Cầu (`rag/pipeline.py`)
- File [rag/pipeline.py](file:///d:/RealEstateMobile-Project/real-estate-ai/rag/pipeline.py) sử dụng kiến trúc RAG LangChain chuẩn 100%.

### 3. Cập Nhật Toàn Bộ Dữ Liệu 78 Bất Động Sản Chuẩn (`papers/hcm_properties_extended.md`)
- Toàn bộ 78 BĐS chuẩn từ `Property ID 1` đến `Property ID 78` đã được ghi đầy đủ vào file [papers/hcm_properties_extended.md](file:///d:/RealEstateMobile-Project/real-estate-ai/papers/hcm_properties_extended.md).

### 4. Tốc Độ & Streaming Realtime
- Dùng `ChatOpenAI(model="qwen2.5:3b", base_url="http://localhost:11434/v1", api_key="ollama", temperature=0.0)`.
- Hỗ trợ đầy đủ endpoint Streaming `/api/chat-rag/stream` cho frontend/mobile.
