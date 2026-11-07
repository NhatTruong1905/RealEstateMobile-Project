import asyncio
import logging
import time
from dotenv import load_dotenv
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnableLambda
from api.schemas import RealEstateIntentSummary
from rag.config import Settings
from rag.providers import create_embedding, create_llm
from rag.conversation import ConversationManager, sanitize_and_budget_history
from rag.context import ContextBuilder
from rag.filters import filter_documents, is_pure_greeting, format_docs_with_greeting_check
from rag.output import clean_output_text
from rag.prompts import ANSWER_PROMPT
from rag.retriever import create_retriever
from rag.qdrant_store import QdrantParentStore
from rag.reranker import Reranker

load_dotenv()
log = logging.getLogger(__name__)


class RAGPipeline:
    def __init__(self, papers_dir: str = "./papers", db_dir: str = "./vector_database"):
        self.papers_dir = papers_dir
        self.db_dir = db_dir
        self.rag_chain = None
        self.retriever = None
        self.summary_chain = None


    def initialize(self):
        self.settings = Settings.from_env()
        try:
            embedding = create_embedding(self.settings)
            llm = create_llm(self.settings)
            self.summary_chain = create_llm(self.settings).with_structured_output(RealEstateIntentSummary)
            self.retriever = create_retriever(self.settings, embedding, self.db_dir,
                                              store_factory=QdrantParentStore)
            self.reranker = Reranker(self.settings)
            prompt = ChatPromptTemplate.from_template(ANSWER_PROMPT)
            self.rag_chain = (
                {
                    "context": RunnableLambda(self.get_context_for_chain),
                    "history": RunnableLambda(lambda x: x["history_str"]),
                    "question": RunnableLambda(lambda x: x["question"]),
                }
                | prompt | llm | StrOutputParser()
            )
        except Exception:
            self.close()
            raise

    def get_context_for_chain(self, inputs):
        return ContextBuilder(self.settings, self.retriever, self.reranker).build(inputs)

    def _extract_intent_from_history(self, history_list):
        return ConversationManager(self.summary_chain)._extract_intent_from_history(history_list)

    def _prepare_inputs(self, question, history=None):
        return ConversationManager(self.summary_chain)._prepare_inputs(question, history)

    def _clean_output_text(self, text):
        return clean_output_text(text)


    def close(self):
        if hasattr(self, "reranker"):
            self.reranker.close()
        if hasattr(self.retriever, "close"):
            self.retriever.close()


    def query(self, question: str, history: list = None) -> str:
        if not self.rag_chain:
            raise RuntimeError("RAG Pipeline chưa được khởi tạo!")
        inputs = self._prepare_inputs(question, history)
        start = time.monotonic()
        raw_answer = self.rag_chain.invoke(inputs)
        log.info("chat elapsed_ms=%.1f", (time.monotonic()-start)*1000)
        return self._clean_output_text(raw_answer)


    async def query_astream(self, question: str, history: list = None):
        if not self.rag_chain:
            raise RuntimeError("RAG Pipeline chưa được khởi tạo!")
        inputs = await asyncio.to_thread(self._prepare_inputs, question, history)
        start = time.monotonic()
        try:
            async for chunk in self.rag_chain.astream(inputs):
                yield self._clean_output_text(chunk)
        finally:
            log.info("chat_stream elapsed_ms=%.1f", (time.monotonic()-start)*1000)



rag_service = RAGPipeline()
