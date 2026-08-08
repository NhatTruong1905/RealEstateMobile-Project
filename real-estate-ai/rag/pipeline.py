import re
from langchain_community.document_loaders import DirectoryLoader, TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS
from langchain_classic.retrievers import ParentDocumentRetriever
from langchain_core.stores import InMemoryStore
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_core.documents import Document
from langchain_openai import ChatOpenAI
from langchain_ollama import OllamaEmbeddings


def format_docs(docs):
    if not docs:
        return "Hiện tại không có bất động sản nào ở trạng thái Đang mở bán phù hợp với yêu cầu."
    formatted = []
    for i, doc in enumerate(docs, 1):
        source = doc.metadata.get("source", "Tài liệu hệ thống")
        formatted.append(f"--- [Tài liệu {i}] (Nguồn: {source}) ---\n{doc.page_content}")
    return "\n\n".join(formatted)


class RAGPipeline:
    def __init__(self, papers_dir: str = "./papers"):
        self.papers_dir = papers_dir
        self.rag_chain = None

    def _load_and_filter_documents(self) -> list[Document]:
        loader = DirectoryLoader(
            path=self.papers_dir,
            glob="**/*.md",
            loader_cls=TextLoader,
            loader_kwargs={"encoding": "utf-8"},
            show_progress=True
        )
        raw_docs = loader.load()
        cleaned_docs = []

        for doc in raw_docs: #hcm_properties
            source = doc.metadata.get("source", "")
            if "hcm_properties" in source:
                content = doc.page_content
                blocks = re.split(r"(\n\n- \*\*Property ID|\n- \*\*Property ID)", content)

                valid_parts = [blocks[0]]  # Header của file markdown
                for i in range(1, len(blocks), 2):
                    header_prefix = blocks[i]
                    body = blocks[i + 1] if i + 1 < len(blocks) else ""
                    full_block = header_prefix + body

                    if "Trạng thái: Đang mở bán" in full_block:
                        valid_parts.append(full_block)

                cleaned_content = "".join(valid_parts)
                cleaned_docs.append(Document(page_content=cleaned_content, metadata=doc.metadata))
            else:
                cleaned_docs.append(doc)

        return cleaned_docs

    def initialize(self):
        embedding = OllamaEmbeddings(model="bge-m3")
        llm = ChatOpenAI(
            model="qwen2.5:7b",
            base_url="http://localhost:11434/v1",
            api_key="ollama",
            temperature=0.0
        )

        docs = self._load_and_filter_documents()

        MARKDOWN_SEPARATORS = [
            r"\n\n- \*\*Property ID",
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
            chunk_size=600,
            chunk_overlap=0,
            add_start_index=True,
            strip_whitespace=True,
            is_separator_regex=True,
            separators=MARKDOWN_SEPARATORS,
        )

        child_splitter = RecursiveCharacterTextSplitter(
            chunk_size=250,
            chunk_overlap=30
        )

        # 4. In-Memory Store chứa Parent Documents
        docstore = InMemoryStore()

        # 5. Khởi tạo FAISS Vector Store rỗng cho Child Chunks
        initial_child_splits = child_splitter.split_documents(parent_splitter.split_documents(docs[:1]))
        vectorstore = FAISS.from_documents(initial_child_splits, embedding)

        # 6. Khởi tạo ParentDocumentRetriever
        retriever = ParentDocumentRetriever(
            vectorstore=vectorstore,
            docstore=docstore,
            child_splitter=child_splitter,
            parent_splitter=parent_splitter,
        )

        retriever.add_documents(docs)

        # Rules
        template = """Bạn là một Chuyên viên Tư vấn Bất động sản AI chuyên nghiệp, am hiểu thị trường TP. Hồ Chí Minh.
Nhiệm vụ của bạn là lắng nghe nhu cầu của khách hàng (về Địa chỉ/Khu vực, Mức giá/Ngân sách, Loại bất động sản Mua/Thuê, Số phòng ngủ, Tiện ích...) và đưa ra các gợi ý phù hợp dựa trên dữ liệu hệ thống.

NGUYÊN TẮC VÀ RÀNG BUỘC CHẶT CHẼ:
1. TÁC PHONG CHUYÊN NGHIỆP: Trả lời tự nhiên, lịch sự, tư vấn tận tâm như một chuyên viên bất động sản thực thụ.
2. NÓI KHÔNG VỚI CÂU TỪ CỨNG NHẮC: TUYỆT ĐỐI KHÔNG dùng các cụm từ máy móc như "Theo tài liệu được cung cấp", "Được liệt kê trong tài liệu", "Dựa vào dữ liệu trên", "Dựa trên file md". Hãy diễn đạt tự nhiên như dữ liệu là từ hệ thống danh mục bất động sản của bạn.
3. CHÍNH XÁC TUYỆT ĐỐI VỀ MỨC GIÁ VÀ CON SỐ: Khi báo Mức giá (Giá bán/Giá thuê), Diện tích, Số phòng ngủ/WC của bất kỳ Bất động sản nào, BẮT BUỘC phải trích dẫn CHÍNH XÁC NGUYÊN VĂN con số ghi trong dữ liệu (Ví dụ: "4,500,000,000 VNĐ (4.5 Tỷ)" hoặc "15,000,000 VNĐ/tháng"). TUYỆT ĐỐI KHÔNG tự tính toán lại, không tự làm tròn, không gán mức giá của BĐS này sang BĐS khác.
4. BẮT BUỘC CHỈ NÊU BẤT ĐỘNG SẢN "ĐANG MỞ BÁN": Toàn bộ bất động sản trong hệ thống dữ liệu của bạn đều đang mở bán. Hãy tự tin tư vấn thông tin chính xác từng căn cho khách hàng.
5. XỬ LÝ KHI KHÔNG CÓ KẾT QUẢ KHỚP 100%: Nếu ngân sách hoặc vị trí khách hàng yêu cầu chưa có BĐS khớp hoàn toàn trong dữ liệu, hãy lịch sự thông báo và gợi ý các lựa chọn gần nhất hoặc có mức giá/vị trí tương đương có trong dữ liệu.
6. TRÌNH BÀY ĐẸP MẮT: Khi gợi ý BĐS, hãy trình bày rõ ràng từng lựa chọn bao gồm:
   - Tên/Mã BĐS
   - Vị trí / Địa chỉ chi tiết
   - Mức giá (Giá bán hoặc Giá thuê)
   - Quy mô / Diện tích / Số phòng
   - Đặc điểm nổi bật & Tiện ích

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
        return self.rag_chain.invoke(question)


rag_service = RAGPipeline()
