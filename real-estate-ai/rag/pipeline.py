import os
import re
import uuid
import time
import pickle
from dotenv import load_dotenv
from langchain_community.document_loaders import DirectoryLoader, TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.vectorstores import FAISS
from langchain_classic.retrievers import ParentDocumentRetriever
from langchain_core.stores import InMemoryStore
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough, RunnableLambda
from langchain_google_genai import ChatGoogleGenerativeAI, GoogleGenerativeAIEmbeddings

load_dotenv()
GEMINI_API_KEY = os.getenv("GOOGLE_API_KEY")


def is_pure_greeting(question: str) -> bool:
    q_clean = re.sub(r"[^\w\s]", "", question.lower().strip())
    greeting_words = {"chào", "xin chào", "chào bạn", "chào em", "chào anh", "chào chị", "hi", "hello", "hey",
                      "chào shop", "chào ad", "chào admin"}
    words = q_clean.split()

    re_keywords = ["mua", "thuê", "bán", "giá", "tỷ", "triệu", "phòng", "căn hộ", "nhà", "quận", "đất", "dự án",
                   "biệt thự", "pháp lý"]

    has_re_intent = any(kw in q_clean for kw in re_keywords)
    if not has_re_intent:
        if q_clean in greeting_words or any(w in greeting_words for w in words):
            return True
    return False


def extract_budget(question: str) -> float:
    q_lower = question.lower()
    ty_match = re.search(r"(\d+(?:[.,]\d+)?)\s*tỷ", q_lower)
    trieu_match = re.search(r"(\d+(?:[.,]\d+)?)\s*triệu", q_lower)

    if ty_match:
        val_str = ty_match.group(1).replace(",", ".")
        return float(val_str) * 1_000_000_000
    elif trieu_match:
        val_str = trieu_match.group(1).replace(",", ".")
        return float(val_str) * 1_000_000
    return None


def extract_price(content: str) -> float:
    price_match = re.search(r"mức giá:\s*([\d,.]+)", content.lower())
    if price_match:
        price_raw = price_match.group(1).replace(",", "").replace(".", "")
        try:
            return float(price_raw)
        except ValueError:
            pass
    return None


def format_history_text(history: list) -> str:
    if not history:
        return "Không có lịch sử hội thoại trước đó."
    formatted = []
    for item in history:
        if hasattr(item, "role"):
            role = item.role
            content = item.content
        elif isinstance(item, dict):
            role = item.get("role", "user")
            content = item.get("content", "")
        else:
            continue
        role_label = "Khách hàng" if role == "user" else "Trợ lý AI"
        if content and content.strip():
            formatted.append(f"{role_label}: {content.strip()}")
    if not formatted:
        return "Không có lịch sử hội thoại trước đó."
    return "\n".join(formatted)


def format_docs_with_greeting_check(inputs: dict) -> str:
    docs = inputs.get("docs", [])
    question = inputs.get("question", "")
    search_query = inputs.get("search_query", question)
    q_lower = search_query.lower()

    if is_pure_greeting(question):
        return "CHỈ_CHÀO_HỎI_KHÔNG_CÓ_NHU_CẦU_BĐS"

    budget = extract_budget(search_query)

    is_buy = any(kw in q_lower for kw in ["mua", "sang nhượng", "cần mua", "tìm mua", "bán", "muốn"])
    is_rent = any(kw in q_lower for kw in ["cho thuê", "tìm thuê", "cần thuê"]) or ("thuê" in q_lower and not is_buy)

    if budget is not None:
        if budget >= 100_000_000:
            is_buy = True
            is_rent = False
        else:
            is_rent = True
            is_buy = False

    seen_ids = set()
    filtered_docs = []

    for doc in docs:
        content = doc.page_content
        content_lower = content.lower()

        prop_id_match = re.search(r"property id\s*(\d+)", content_lower)
        if prop_id_match:
            pid = prop_id_match.group(1)
            if pid in seen_ids:
                continue
            seen_ids.add(pid)

        if "đang mở bán" not in content_lower:
            continue

        if is_buy:
            if "loại giao dịch: bán" not in content_lower and "bán (sale)" not in content_lower:
                continue
        elif is_rent:
            if "loại giao dịch: cho thuê" not in content_lower and "cho thuê (rent)" not in content_lower:
                continue

        if budget is not None:
            doc_price = extract_price(content_lower)
            if doc_price is not None and doc_price > budget:
                continue

        filtered_docs.append(content)

    if not filtered_docs:
        return "KHÔNG_CÓ_BĐS_PHÙ_HỢP_VỚI_NGÂN_SÁCH"

    return "\n\n".join(filtered_docs)


def add_documents_safely(retriever, docs, batch_size=5, sleep_sec=3.5):
    parent_docs = retriever.parent_splitter.split_documents(docs)  # CHA

    doc_ids = []
    full_child_docs = []

    for p_doc in parent_docs:
        p_id = str(uuid.uuid4())
        doc_ids.append(p_id)
        p_doc.metadata["doc_id"] = p_id

        sub_children = retriever.child_splitter.split_documents([p_doc])  # CON
        for c_doc in sub_children:
            c_doc.metadata["doc_id"] = p_id
            full_child_docs.append(c_doc)

    retriever.docstore.mset(list(zip(doc_ids, parent_docs)))  # THÊM VÀO DOCSTORE

    if full_child_docs:
        total_batches = (len(full_child_docs) + batch_size - 1)
        print(
            f"[RAGPipeline] Đang tạo Gemini Embeddings cho {len(full_child_docs)} child chunks ({total_batches} batches)...",
            flush=True)
        for i in range(0, len(full_child_docs), batch_size):
            batch = full_child_docs[i: i + batch_size]

            success = False
            for attempt in range(5):
                try:
                    retriever.vectorstore.add_documents(batch)  # THÊM VÀO VECTOR DATABASE
                    success = True
                    break
                except Exception as e:
                    if "RESOURCE_EXHAUSTED" in str(e) or "429" in str(e):
                        print(f"  [Rate Limit] Chờ 20s do chạm giới hạn Gemini API Free Tier (lần {attempt + 1})...",
                              flush=True)
                        time.sleep(20)
                    else:
                        raise e
            if not success:
                raise RuntimeError("Không thể nạp Gemini Embeddings sau 5 lần thử.")

            print(f"  -> Đã nạp batch {i // batch_size + 1}/{total_batches}...", flush=True)
            time.sleep(sleep_sec)


class RAGPipeline:
    def __init__(self, papers_dir: str = "./papers", db_dir: str = "./vector_database"):
        self.papers_dir = papers_dir
        self.db_dir = db_dir
        self.rag_chain = None
        self.retriever = None

    def initialize(self):
        if not GEMINI_API_KEY:
            raise ValueError("Không tìm thấy GOOGLE_API_KEY trong file .env!")

        print("[RAGPipeline] Đang khởi tạo Google Gemini (LLM: gemini-3.5-flash, Embedding: gemini-embedding-001)...",
              flush=True)
        embedding = GoogleGenerativeAIEmbeddings(
            model="models/gemini-embedding-001",
            google_api_key=GEMINI_API_KEY
        )
        llm = ChatGoogleGenerativeAI(
            model="gemini-3.5-flash",
            google_api_key=GEMINI_API_KEY,
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
            print(f"[RAGPipeline] Tìm thấy Gemini Vector DB tại '{self.db_dir}'. Nạp dữ liệu trực tiếp từ đĩa...",
                  flush=True)
            vectorstore = FAISS.load_local(
                folder_path=self.db_dir,
                embeddings=embedding,
                allow_dangerous_deserialization=True
            )
            docstore = InMemoryStore()
            with open(docstore_path, "rb") as f:
                saved_store = pickle.load(f)
            docstore.mset(list(saved_store.items()))
            print("[RAGPipeline] Nạp thành công Gemini Vector DB & DocStore từ đĩa!", flush=True)
        else:
            print(
                f"[RAGPipeline] Chưa có Vector DB Gemini. Đang tạo embedding từ Gemini API và lưu vào '{self.db_dir}'...",
                flush=True)
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
                search_kwargs={"k": 25}
            )
            add_documents_safely(retriever_builder, docs, batch_size=5, sleep_sec=3.5)

            os.makedirs(self.db_dir, exist_ok=True)
            vectorstore.save_local(self.db_dir)
            with open(docstore_path, "wb") as f:
                pickle.dump(docstore.store, f)
            print(f"[RAGPipeline] Khởi tạo & Lưu thành công Gemini Vector DB vào đĩa '{self.db_dir}'!", flush=True)

        retriever = ParentDocumentRetriever(
            vectorstore=vectorstore,
            docstore=docstore,
            child_splitter=child_splitter,
            parent_splitter=parent_splitter,
            search_kwargs={"k": 25}
        )
        self.retriever = retriever

        template = """Bạn là một Chuyên viên Tư vấn Bất động sản AI chuyên nghiệp, uy tín tại TP. Hồ Chí Minh.
Nhiệm vụ của bạn là tư vấn thông tin bất động sản cho khách hàng một cách chính xác, lịch sự và trung thực nhất dựa duy nhất trên dữ liệu danh mục được cung cấp.

BỘ QUY TẮC VÀ RÀNG BUỘC NGHIÊM NGẶT:
1. XỬ LÝ KHI KHÔNG CÓ BĐS PHÙ HỢP HOẶC GIÁ > NGÂN SÁCH:
   - NẾU DỮ LIỆU GHI "KHÔNG_CÓ_BĐS_PHÙ_HỢP_VỚI_NGÂN_SÁCH" HOẶC KHÔNG CÓ BĐS NÀO CÓ GIÁ <= NGÂN SÁCH:
     + LỊCH SỰ VÀ THÂN THIỆN THÔNG BÁO: "Rất tiếc, hiện tại hệ thống chưa có bất động sản nào đáp ứng mức giá nhỏ hơn hoặc bằng ngân sách của bạn. Bạn có thể cân nhắc điều chỉnh mức ngân sách hoặc tiêu chí tìm kiếm."
     + TUYỆT ĐỐI KHÔNG LIỆT KÊ BẤT KỲ BẤT ĐỘNG SẢN NÀO CÓ GIÁ LỚN HƠN NGÂN SÁCH KHÁCH HÀNG.

2. XỬ LÝ CÂU CHÀO HỎI / XÃ GIAO (STRICT GREETING RULE):
   - NẾU DỮ LIỆU GHI "CHỈ_CHÀO_HỎI_KHÔNG_CÓ_NHU_CẦU_BĐS" HOẶC KHÁCH HÀNG CHỈ CHÀO HỎI (Ví dụ: "Chào bạn", "Xin chào", "Hi"):
     + CHỈ ĐÁP LẠI LỊCH SỰ, THÂN THIỆN VÀ ẤM ÁP: "Xin chào bạn! Tôi là Chuyên viên Tư vấn Bất động sản AI tại TP.HCM. Tôi có thể hỗ trợ gì cho bạn hôm nay?"
     + TUYỆT ĐỐI KHÔNG LIỆT KÊ, KHÔNG GỢI Ý BẤT KỲ BẤT ĐỘNG SẢN NÀO khi khách hàng chưa đưa ra yêu cầu tìm kiếm cụ thể.

3. TRUNG THỰC & CHỐNG BỊA ĐẶT (ZERO HALLUCINATION):
   - CHỈ tư vấn các bất động sản có trong "Dữ liệu danh mục Bất động sản hệ thống" bên dưới.
   - TUYỆT ĐỐI KHÔNG tự sáng tạo, suy đoán hoặc giới thiệu bất kỳ bất động sản nào KHÔNG CÓ trong dữ liệu.

4. LỌC LOẠI GIAO DỊCH CHÍNH XÁC (STRICT TRANSACTION TYPE FILTER - BÁN VS. CHO THUÊ):
   - Khi khách hàng muốn "MUA" (hoặc tìm nhà để bán, tài chính mua nhà): CHỈ ĐỀ XUẤT các bất động sản có Loại giao dịch là "Bán (Sale)". TUYỆT ĐỐI KHÔNG đề xuất bất động sản "Cho thuê (Rent)".
   - Khi khách hàng muốn "THUÊ" (hoặc tìm nhà cho thuê): CHỈ ĐỀ XUẤT các bất động sản có Loại giao dịch là "Cho thuê (Rent)". TUYỆT ĐỐI KHÔNG đề xuất bất động sản "Bán (Sale)".

5. LỌC SỐ PHÒNG NGỦ CHÍNH XÁC (STRICT ROOM COUNT FILTER):
   - Khi khách hàng chỉ định rõ số phòng ngủ (Ví dụ: "2 phòng ngủ", "3 phòng ngủ"): CHỈ ĐỀ XUẤT các bất động sản có ĐÚNG số phòng ngủ mà khách hàng đã yêu cầu.

6. ĐÚNG TRỌNG TÂM & TUYỆT ĐỐI KHÔNG THÊM CÂU XÃ GIAO / GỢI Ý THỪA Ó CUỐI:
   - DỪNG CÂU TRẢ LỜI NGAY LẬP TỨC sau khi liệt kê xong danh sách bất động sản.
   - TUYỆT ĐỐI KHÔNG thêm bất kỳ câu xã giao, câu kết hay gợi ý thừa nào ở cuối như: "Nếu bạn quan tâm đến bất động sản nào...", "Vui lòng cho tôi biết...", "Tôi có thể giúp gì thêm...".

7. HIỂN THỊ ĐẦY ĐỦ TIÊU ĐỀ & KHÔNG DÙNG DẤU SAO (*):
   - Khi giới thiệu bất kỳ bất động sản nào, BẮT BUỘC phải hiển thị đầy đủ Mã BĐS kèm Tiêu đề BĐS chính xác từ dữ liệu theo dạng: "Property ID [Số]: [Tiêu đề BĐS]".
   - Trình bày đầy đủ thông tin: Địa chỉ, Mức giá, Diện tích, Quy mô/Số phòng ngủ, Pháp lý, Mô tả.
   - TUYỆT ĐỐI KHÔNG DÙNG DẤU SAO (*) trong toàn bộ câu trả lời (không dùng in đậm/in nghiêng markdown).

8. DUY TRÌ NGỮ CẢNH HỘI THOẠI (CHAT CONTEXT & HISTORY):
   - Dựa vào 'Lịch sử hội thoại trước đó' và 'Câu hỏi hiện tại' để hiểu mạch hội thoại liên tục của khách hàng.
   - Nếu câu hỏi trước khách hàng hỏi tìm mua nhà Quận 7 dưới 3 tỷ, và câu sau hỏi 'Căn nào 2 phòng ngủ?', hãy tự hiểu khách hàng vẫn muốn tìm nhà Quận 7 dưới 3 tỷ có 2 phòng ngủ.

Lịch sử hội thoại trước đó:
{history}

Dữ liệu danh mục Bất động sản hệ thống:
{context}

Câu hỏi / Yêu cầu tư vấn hiện tại của khách hàng: {question}

Lời tư vấn chuyên nghiệp của bạn:"""

        prompt = ChatPromptTemplate.from_template(template)

        def get_context_for_chain(inputs: dict) -> str:
            sq = inputs.get("search_query", inputs.get("question", ""))
            docs = self.retriever.invoke(sq)
            return format_docs_with_greeting_check({
                "docs": docs,
                "question": inputs.get("question", ""),
                "search_query": sq
            })

        self.rag_chain = (
                {
                    "context": RunnableLambda(get_context_for_chain),
                    "history": RunnableLambda(lambda x: x["history_str"]),
                    "question": RunnableLambda(lambda x: x["question"])
                }
                | prompt
                | llm
                | StrOutputParser()
        )

    def _prepare_inputs(self, question: str, history: list = None) -> dict:
        history_list = history or []
        history_str = format_history_text(history_list)

        user_texts = []
        for item in history_list:
            role = item.role if hasattr(item, "role") else (item.get("role") if isinstance(item, dict) else "")
            content = item.content if hasattr(item, "content") else (
                item.get("content") if isinstance(item, dict) else "")
            if role == "user" and content and content.strip():
                user_texts.append(content.strip())

        search_query = " ".join(user_texts + [question.strip()]) if user_texts else question.strip()

        return {
            "question": question.strip(),
            "search_query": search_query,
            "history_str": history_str,
        }

    def query(self, question: str, history: list = None) -> str:
        if not self.rag_chain:
            raise RuntimeError("RAG Pipeline chưa được khởi tạo!")
        inputs = self._prepare_inputs(question, history)
        raw_answer = self.rag_chain.invoke(inputs)
        return raw_answer.replace("*", "")

    async def query_astream(self, question: str, history: list = None):
        if not self.rag_chain:
            raise RuntimeError("RAG Pipeline chưa được khởi tạo!")
        inputs = self._prepare_inputs(question, history)
        async for chunk in self.rag_chain.astream(inputs):
            yield chunk.replace("*", "")


rag_service = RAGPipeline()
