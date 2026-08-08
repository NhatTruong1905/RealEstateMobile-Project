# NHẬT KÝ THAY ĐỔI & TỐI ƯU HỆ THỐNG RAG (RAG SYSTEM CHANGE LOG)

## 💡 Tại sao Parent-Child lại là phương pháp tối ưu nhất cho RAG Bất động sản?

Trong các bài toán tra cứu BĐS, nếu dùng chunk quá to thì vector search không nhạy, nếu dùng chunk quá nhỏ thì thông tin bị đứt đoạn. Parent-Child giải quyết triệt để vấn đề này:

* **Child Chunks (Khối nhỏ ~250 ký tự)**:
  - Dùng để tính toán Embedding và lưu vào FAISS Vector Store.
  - **Ưu điểm**: Giúp Vector Search khớp cực kỳ chính xác các từ khóa chi tiết của người dùng như *"2 phòng ngủ"*, *"ngân sách 15 triệu"*, *"Quận 7"*, *"Sổ hồng"*.

* **Parent Chunks (Khối 1 căn BĐS ~600 ký tự)**:
  - Được lưu trong `docstore` (bộ nhớ trung gian).
  - Khi Child Chunk được tìm thấy, `ParentDocumentRetriever` sẽ tự động tra ngược và lấy ra toàn bộ khối Parent hoàn chỉnh chứa đầy đủ thông tin của BĐS đó (Tên BĐS, Địa chỉ, Giá, Diện tích, Trạng thái, Mô tả).

👉 **Kết quả**: LLM luôn nhận được ngữ cảnh trọn vẹn của từng căn BĐS mà không sợ bị ngắt ngang hay mất thông tin tiêu đề.

---

## 📝 TỔNG HỢP TOÀN BỘ CÁC THAY ĐỔI VÀ TỐI ƯU TRONG HỆ THỐNG RAG (`rag/pipeline.py`)

### 1. Sửa lỗi sai số Mức Giá (Price Precision Optimization)
- **Vấn đề**: Đôi khi giá bán/giá thuê trả về bị sai khác hoặc nhầm lẫn giữa các BĐS.
- **Nguyên nhân**:
  1. `parent_splitter` có `chunk_size=1200` dồn nhiều BĐS vào 1 chunk làm LLM bị nhầm giá của căn này sang căn khác.
  2. `temperature=0.1` tạo độ trôi ngẫu nhiên khi LLM sinh các con số.
- **Giải pháp xử lý triệt để**:
  1. **Đảm bảo 1 Parent Chunk = 1 BĐS duy nhất**: Đổi `chunk_size=600` và `chunk_overlap=0` kết hợp separator `r"\n\n- \*\*Property ID"`. Mỗi khối Parent Chunk giờ đây chỉ chứa DUY NHẤT 1 BĐS, triệt tiêu 100% việc nhầm lẫn giá giữa các BĐS khác nhau.
  2. **Triệt tiêu biến động nhiệt độ**: Thiết lập `temperature=0.0` trong `ChatOpenAI`.
  3. **Thêm Rule 3 khắt khe**: Ép LLM phải trích dẫn **CHÍNH XÁC NGUYÊN VĂN** con số mức giá/diện tích ghi trong dữ liệu, không tự làm tròn hay tính toán lại.

### 3. Sửa lỗi triệt để 100%: Lọc cứng BĐS từ tầng Loader (`_load_and_filter_documents`)
- **Phát hiện nguyên nhân gốc**: BĐS bị từ chối (`Property ID 44`) bị nằm chung khối với BĐS mở bán làm lọt qua bộ lọc cũ.
- **Giải pháp**: Thêm hàm `_load_and_filter_documents()` ngay ở cấp độ Loader. Khi nạp file `hcm_properties_extended.md`, code Python dùng Regex bóc tách từng khối BĐS và **HỦY BỎ HOÀN TOÀN (DISCARD)** mọi BĐS có trạng thái *"Từ chối"*, *"Chờ duyệt"*, *"Đã xóa"* trước khi đưa vào splitter hay vectorstore.
  - **Kết quả**: CHỈ CÓ các BĐS đang mở bán tồn tại trong bộ nhớ. `Property ID 44` bị xóa sạch 100% từ đầu nên tuyệt đối không bao giờ xuất hiện hay bị AI bịa sai thông tin nữa.

### 4. Nâng cấp System Prompt & Bộ Quy Tắc (Rules) Chặt Chẽ
- **Đóng vai Chuyên viên Tư vấn Bất động sản AI**: Chuyển phong cách trả lời từ máy móc sang tư vấn viên bất động sản chuyên nghiệp tại TP.HCM.
- **Loại bỏ câu chữ cứng nhắc**: Cấm tuyệt đối các cụm từ như *"Theo tài liệu được cung cấp"*, *"Được liệt kê trong tài liệu"*, *"Dựa trên file md"*.

### 5. Tối ưu Bộ Chia Văn Bản (Text Splitter & Document Loader)
- **Thay đổi Loader**: Đổi từ `UnstructuredMarkdownLoader` sang `TextLoader` (`encoding="utf-8"`).
  - *Lý do*: `UnstructuredMarkdownLoader` tự động xóa mất các dấu cú pháp Markdown (`#`, `##`, `- **Property ID`), làm vô hiệu hóa các quy tắc ngắt đoạn Markdown Separators. `TextLoader` giữ nguyên 100% cú pháp gốc.
- **Cấu hình Text Splitter**:
  - Thêm `is_separator_regex=True` để `RecursiveCharacterTextSplitter` hiểu biểu thức chính quy Regex.
  - Thêm `add_start_index=True` và `strip_whitespace=True`.

### 6. Chuyển sang kết nối mô hình local qua giao thức OpenAI API tương thích
- **Cài đặt thư viện**: Thêm `langchain-openai`.
- **Cấu hình LLM**: Chuyển từ `ChatOllama` sang `ChatOpenAI(model="qwen2.5:7b", base_url="http://localhost:11434/v1", api_key="ollama")`.
- **Hạ Model**: Chuyển từ `qwen2.5:14b` xuống `qwen2.5:7b` để tăng tốc độ phản hồi và nhẹ tải cho phần cứng local.

### 7. Chuyển đổi Kiến trúc Chunking sang Parent-Child (`ParentDocumentRetriever`)
- Thêm `InMemoryStore` lưu trữ tài liệu cha (`docstore`).
- Sử dụng `parent_splitter` (`chunk_size=600`, `chunk_overlap=0`) để giữ trọn vẹn 1 BĐS per chunk.
- Sử dụng `child_splitter` (`chunk_size=250`, `chunk_overlap=30`) để vector search trong FAISS cực kỳ nhạy bén.
- Khởi tạo `ParentDocumentRetriever` kết hợp giữa FAISS VectorStore và `InMemoryStore`.
