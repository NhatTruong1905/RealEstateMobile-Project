import asyncio
import logging
import re
import time
from dotenv import load_dotenv
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from api.schemas import RealEstateIntentSummary
from rag.config import Settings
from rag.providers import create_embedding, create_llm
from rag.conversation import ConversationManager, sanitize_and_budget_history
from rag.context import ContextBuilder
from rag.output import clean_output_text
from rag.prompts import ANSWER_PROMPT
from rag.retriever import create_retriever
from rag.qdrant_store import QdrantParentStore
from rag.reranker import Reranker

load_dotenv()
log = logging.getLogger(__name__)


class RAGPipeline:
    def __init__(self):
        self.rag_chain = None
        self.retriever = None
        self.summary_chain = None


    def initialize(self):
        self.settings = Settings.from_env()
        try:
            embedding = create_embedding(self.settings)
            llm = create_llm(self.settings)
            self.summary_chain = create_llm(self.settings).with_structured_output(RealEstateIntentSummary)
            self.retriever = create_retriever(self.settings, embedding,
                                              store_factory=QdrantParentStore)
            self.reranker = Reranker(self.settings)
            prompt = ChatPromptTemplate.from_template(ANSWER_PROMPT)
            self.rag_chain = prompt | llm | StrOutputParser()
        except Exception:
            self.close()
            raise

    def prepare_context(self, question, history):
        inputs = self._prepare_inputs(question, history)
        context, documents = ContextBuilder(self.settings, self.retriever, self.reranker).build(inputs)
        return dict(context=context, history=inputs["history_str"], question=inputs["question"]), documents

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
        start = time.monotonic()
        inputs, _ = self.prepare_context(question, history)
        raw_answer = self.rag_chain.invoke(inputs)
        log.info("chat elapsed_ms=%.1f", (time.monotonic()-start)*1000)
        return self._clean_output_text(raw_answer)


    async def query_astream(self, question: str, history: list = None):
        async for kind, value in self.stream_events(question, history):
            if kind == "delta":
                yield value

    async def stream_events(self, question, history=None):
        if not self.rag_chain:
            raise RuntimeError("RAG Pipeline chưa được khởi tạo!")
        start = time.monotonic()
        try:
            inputs, documents = await asyncio.to_thread(self.prepare_context, question, history)
            answer = []
            async for chunk in self.rag_chain.astream(inputs):
                text = self._clean_output_text(chunk)
                answer.append(text)
                yield "delta", text
            cited_ids = set(re.findall(r"\bProperty ID\s*:?\s*(\d+)\b", "".join(answer), re.IGNORECASE))
            yield "properties", [
                {key: str(doc.metadata.get(key, "")) for key in
                 ("property_id", "title", "price_vnd", "area_m2", "district", "ward", "type")}
                for doc in documents if str(doc.metadata.get("property_id")) in cited_ids
            ]
        finally:
            log.info("chat_stream elapsed_ms=%.1f", (time.monotonic()-start)*1000)



rag_service = RAGPipeline()
