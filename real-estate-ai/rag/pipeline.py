import os
import re
import pickle
from langchain_community.document_loaders import DirectoryLoader, TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS
from langchain_classic.retrievers import ParentDocumentRetriever
from langchain_core.stores import InMemoryStore
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_openai import ChatOpenAI
from langchain_ollama import OllamaEmbeddings


class SafeOllamaEmbeddings(OllamaEmbeddings):
    def embed_documents(self, texts: list[str]) -> list[list[float]]:
        results = []
        for text in texts:
            response = self._client.embed(model=self.model, input=text)
            results.append(response["embeddings"][0])
        return results

    def embed_query(self, text: str) -> list[float]:
        response = self._client.embed(model=self.model, input=text)
        return response["embeddings"][0]


def format_docs(docs):
    seen_ids = set()
    formatted = []
    for doc in docs:
        content = doc.page_content
        prop_id_match = re.search(r"property id\s*(\d+)", content.lower())
        if prop_id_match:
            pid = prop_id_match.group(1)
            if pid in seen_ids:
                continue
            seen_ids.add(pid)
        formatted.append(content)
    return "\n\n".join(formatted)


class RAGPipeline:
    def __init__(self, papers_dir: str = "./papers", db_dir: str = "./vector_database"):
        self.papers_dir = papers_dir
        self.db_dir = db_dir
        self.rag_chain = None

    def initialize(self):
        embedding = SafeOllamaEmbeddings(model="bge-m3")
        llm = ChatOpenAI(
            model="qwen2.5:7b",
            base_url="http://localhost:11434/v1",
            api_key="ollama",
            temperature=0.0
        )

        MARKDOWN_SEPARATORS = [
            r"\n- \*\*Property ID ",
            r"\n- \*\*Property ID",
            r"\n#{1,6} ",
            r"```\n",
            r"\n\*{3,}\n",
            r"\n---+\n",
            r"\n___+\n",
            "\n\n",
            "\n",
            " ",
            ""
        ]

        parent_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1200,
            chunk_overlap=0,
            add_start_index=True,
            strip_whitespace=True,
            is_separator_regex=True,
            separators=MARKDOWN_SEPARATORS,
        )

        child_splitter = RecursiveCharacterTextSplitter(
            chunk_size=450,
            chunk_overlap=50
        )

        docstore_path = os.path.join(self.db_dir, "docstore.pkl")
        faiss_index_path = os.path.join(self.db_dir, "index.faiss")

        if os.path.exists(self.db_dir) and os.path.exists(faiss_index_path) and os.path.exists(docstore_path):
            vectorstore = FAISS.load_local(
                folder_path=self.db_dir,
                embeddings=embedding,
                allow_dangerous_deserialization=True
            )
            docstore = InMemoryStore()
            with open(docstore_path, "rb") as f:
                saved_store = pickle.load(f)
            docstore.mset(list(saved_store.items()))
        else:

            loader = DirectoryLoader(
                path=self.papers_dir,
                glob="**/*.md",
                loader_cls=TextLoader,
                loader_kwargs={"encoding": "utf-8"},
                show_progress=True
            )
            docs = loader.load()

            docstore = InMemoryStore()

            initial_child_splits = child_splitter.split_documents(parent_splitter.split_documents(docs[:1]))
            vectorstore = FAISS.from_documents(initial_child_splits, embedding)

            retriever_builder = ParentDocumentRetriever(
                vectorstore=vectorstore,
                docstore=docstore,
                child_splitter=child_splitter,
                parent_splitter=parent_splitter,
                search_kwargs={"k": 10}
            )
            retriever_builder.add_documents(docs)

            os.makedirs(self.db_dir, exist_ok=True)
            vectorstore.save_local(self.db_dir)
            with open(docstore_path, "wb") as f:
                pickle.dump(docstore.store, f)

        retriever = ParentDocumentRetriever(
            vectorstore=vectorstore,
            docstore=docstore,
            child_splitter=child_splitter,
            parent_splitter=parent_splitter,
            search_kwargs={"k": 10}
        )

        template = """Bạn là một Chuyên viên Tư vấn Bất động sản AI chuyên nghiệp, uy tín tại TP. Hồ Chí Minh.
Nhiệm vụ của bạn là tư vấn thông tin bất động sản cho khách hàng một cách chính xác, lịch sự và trung thực nhất dựa duy nhất trên dữ liệu danh mục được cung cấp.

BỘ QUY TẮC VÀ RÀNG BUỘC NGHIÊM NGẶT:
1. TRUNG THỰC & CHỐNG BỊA ĐẶT (ZERO HALLUCINATION):
   - CHỈ tư vấn và trích dẫn các bất động sản có trong "Dữ liệu danh mục Bất động sản hệ thống" bên dưới.
   - TUYỆT ĐỐI KHÔNG tự sáng tạo, suy đoán hoặc giới thiệu bất kỳ bất động sản, dự án, hay thông tin nào KHÔNG CÓ trong dữ liệu.
   - Nếu không có bất động sản nào đáp ứng đúng hoặc đủ tiêu chí tìm kiếm của khách hàng, hãy lịch sự thông báo hiện chưa có bất động sản phù hợp.

2. LỌC LOẠI GIAO DỊCH CHÍNH XÁC (STRICT TRANSACTION TYPE FILTER - BÁN VS. CHO THUÊ):
   - Khi khách hàng muốn "MUA" (hoặc tìm nhà để bán, tài chính mua nhà): CHỈ ĐỀ XUẤT các bất động sản có Loại giao dịch là "Bán (Sale)". TUYỆT ĐỐI KHÔNG đề xuất bất động sản "Cho thuê (Rent)".
   - Khi khách hàng muốn "THUÊ" (hoặc tìm nhà cho thuê): CHỈ ĐỀ XUẤT các bất động sản có Loại giao dịch là "Cho thuê (Rent)". TUYỆT ĐỐI KHÔNG đề xuất bất động sản "Bán (Sale)".

3. LỌC SỐ PHÒNG NGỦ CHÍNH XÁC (STRICT ROOM COUNT FILTER):
   - Khi khách hàng chỉ định rõ số phòng ngủ (Ví dụ: "2 phòng ngủ", "3 phòng ngủ"): CHỈ ĐỀ XUẤT các bất động sản có ĐÚNG số phòng ngủ mà khách hàng đã yêu cầu. TUYỆT ĐỐI KHÔNG đề xuất bất động sản 1 phòng ngủ hay số phòng ngủ khác với yêu cầu của khách hàng.

4. CHỈ TƯ VẤN BẤT ĐỘNG SẢN ĐANG MỞ BÁN:
   - CHỈ giới thiệu các bất động sản có trạng thái "Đang mở bán".
   - TUYỆT ĐỐI KHÔNG tư vấn hay giới thiệu các bất động sản đã bán, đã cho thuê hoặc không có trạng thái "Đang mở bán".

5. QUY TẮC SO SÁNH GIÁ SỐ HỌC NGHIÊM NGẶT (STRICT NUMERIC BUDGET FILTER):
   - NẾU KHÁCH HÀNG ĐƯA RA NGÂN SÁCH (Ví dụ: "4.5 tỷ"): BẮT BUỘC chỉ đề xuất các BĐS có Mức giá <= Ngân sách đó.
   - CHÚ Ý SO SÁNH SỐ HỌC (KHÔNG SO SÁNH CHUỖI VĂN BẢN):
     + 35 Tỷ = 35,000,000,000 VNĐ (35 Tỷ LỚN HƠN RẤT NHIỀU so với 4.5 Tỷ) -> TUYỆT ĐỐI LOẠI BỎ 35 TỶ! KHÔNG ĐƯỢC ĐỀ XUẤT 35 TỶ!
     + 10 Tỷ LỚN HƠN 4.5 Tỷ -> TUYỆT ĐỐI LOẠI BỎ!
     + 4.5 Tỷ BẰNG 4.5 Tỷ -> HỢP LỆ.
     + 3 Tỷ BÉ HƠN 4.5 Tỷ -> HỢP LỆ.
   - TUYỆT ĐỐI KHÔNG đề xuất bất kỳ BĐS nào có giá lớn hơn ngân sách khách yêu cầu.

6. ĐÚNG TRỌNG TÂM & TUYỆT ĐỐI KHÔNG THÊM CÂU XÃ GIAO / GỢI Ý THỪA Ó CUỐI:
   - DỪNG CÂU TRẢ LỜI NGAY LẬP TỨC sau khi liệt kê xong danh sách bất động sản.
   - TUYỆT ĐỐI KHÔNG thêm bất kỳ câu xã giao, câu kết hay gợi ý thừa nào ở cuối như: "Nếu bạn quan tâm đến bất động sản nào...", "Vui lòng cho tôi biết...", "Tôi có thể giúp gì thêm...".

7. HIỂN THỊ ĐẦY ĐỦ TIÊU ĐỀ & KHÔNG DÙNG DẤU SAO (*):
   - Khi giới thiệu bất kỳ bất động sản nào, BẮT BUỘC phải hiển thị đầy đủ Mã BĐS kèm Tiêu đề BĐS chính xác từ dữ liệu theo dạng: "Property ID [Số]: [Tiêu đề BĐS]".
   - Trình bày đầy đủ thông tin: Địa chỉ, Mức giá, Diện tích, Quy mô/Số phòng ngủ, Pháp lý, Mô tả.
   - TUYỆT ĐỐI KHÔNG DÙNG DẤU SAO (*) trong toàn bộ câu trả lời (không dùng in đậm/in nghiêng markdown).

8. XỬ LÝ CÂU CHÀO HỎI / NGOÀI PHẠM VI:
   - Nếu khách hàng chỉ chào hỏi ("Xin chào", "Hi"), chỉ chào lại ngắn gọn và hỏi nhu cầu, KHÔNG gợi ý BĐS khi chưa được hỏi.
   - Nếu hỏi chủ đề ngoài bất động sản, lịch sự từ chối.

Dữ liệu danh mục Bất động sản hệ thống:
{context}

Câu hỏi / Yêu cầu tư vấn của khách hàng: {question}

Lời tư vấn chuyên nghiệp của bạn:"""

        prompt = ChatPromptTemplate.from_template(template)

        self.rag_chain = (
                {"context": retriever | format_docs, "question": RunnablePassthrough()}
                | prompt
                | llm
                | StrOutputParser()
        )

    def query(self, question: str) -> str:
        if not self.rag_chain:
            raise RuntimeError("RAG Pipeline chưa được khởi tạo!")
        raw_answer = self.rag_chain.invoke(question)
        return raw_answer.replace("*", "")

    async def query_astream(self, question: str):
        if not self.rag_chain:
            raise RuntimeError("RAG Pipeline chưa được khởi tạo!")
        async for chunk in self.rag_chain.astream(question):
            yield chunk.replace("*", "")


rag_service = RAGPipeline()
