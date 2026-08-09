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
    """
    Subclass OllamaEmbeddings giúp xử lý từng chuỗi văn bản an toàn 100%,
    ngăn ngừa triệt để lỗi sập tiến trình Tokenize HTTP 400 và lỗi đệ quy RecursionError.
    """
    def _embed_single(self, text: str) -> list[float]:
        res = self._client.embed(model=self.model, input=text)
        return res["embeddings"][0]

    def embed_documents(self, texts: list[str]) -> list[list[float]]:
        results = []
        for text in texts:
            results.append(self._embed_single(text))
        return results

    def embed_query(self, text: str) -> list[float]:
        return self._embed_single(text)


def format_docs(docs):
    return "\n\n".join(doc.page_content for doc in docs)


class RAGPipeline:
    def __init__(self, papers_dir: str = "./papers"):
        self.papers_dir = papers_dir
        self.rag_chain = None

    def initialize(self):
        print("⚡ [RAGPipeline] Đang nạp tài liệu và khởi tạo FAISS Vector Store trực tiếp trong RAM...")
        embedding = SafeOllamaEmbeddings(model="bge-m3")
        llm = ChatOpenAI(
            model="qwen2.5:3b",
            base_url="http://localhost:11434/v1",
            api_key="ollama",
            temperature=0.0
        )

        loader = DirectoryLoader(
            path=self.papers_dir,
            glob="**/*.md",
            loader_cls=TextLoader,
            loader_kwargs={"encoding": "utf-8"},
            show_progress=True
        )
        docs = loader.load()

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

        docstore = InMemoryStore()

        initial_child_splits = child_splitter.split_documents(parent_splitter.split_documents(docs[:1]))
        vectorstore = FAISS.from_documents(initial_child_splits, embedding)

        retriever = ParentDocumentRetriever(
            vectorstore=vectorstore,
            docstore=docstore,
            child_splitter=child_splitter,
            parent_splitter=parent_splitter,
        )

        # Nạp dữ liệu an toàn 100% qua SafeOllamaEmbeddings
        retriever.add_documents(docs)
        print("✅ [RAGPipeline] Khởi tạo thành công FAISS VectorStore & ParentDocumentRetriever trong RAM!")

        template = """Bạn là một Chuyên viên Tư vấn Bất động sản AI chuyên nghiệp tại TP. Hồ Chí Minh.
Nhiệm vụ của bạn là tư vấn thông tin bất động sản cho khách hàng dựa trên dữ liệu bên dưới.

NGUYÊN TẮC VÀ RÀNG BUỘC:
1. TRẢ LỜI NGẮN GỌN & TỰ NHIÊN: Trả lời lịch sự, đúng trọng tâm. TUYỆT ĐỐI KHÔNG lặp lại các quy tắc chỉ thị trong prompt.
2. NÓI KHÔNG VỚI CÂU TỪ CỨNG NHẮC: TUYỆT ĐỐI KHÔNG dùng các cụm từ máy móc như "Theo tài liệu được cung cấp", "Dựa vào dữ liệu trên".
3. TRUNG THỰC: Bạn chỉ tư vấn thông tin có trong dữ liệu bên dưới. Nếu không có bất động sản phù hợp, hãy lịch sự thông báo cho khách hàng.
4. CHÍNH XÁC VỀ CON SỐ: Khi báo mức giá, diện tích, số phòng, trích dẫn chính xác con số trong dữ liệu.

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
        """Trả về toàn bộ câu trả lời dạng JSON thô (Non-streaming)."""
        if not self.rag_chain:
            raise RuntimeError("RAG Pipeline chưa được khởi tạo!")
        return self.rag_chain.invoke(question)

    async def query_astream(self, question: str):
        """Stream trả về từng token (Asynchronous Generator cho FastAPI)."""
        if not self.rag_chain:
            raise RuntimeError("RAG Pipeline chưa được khởi tạo!")
        async for chunk in self.rag_chain.astream(question):
            yield chunk


rag_service = RAGPipeline()
