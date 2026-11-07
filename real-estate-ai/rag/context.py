import logging
import time
from rag.filters import is_pure_greeting, filter_documents, format_docs_with_greeting_check
from rag.source import read_source

log = logging.getLogger(__name__)

class ContextBuilder:
    def __init__(self, settings, retriever, reranker):
        self.settings = settings
        self.retriever = retriever
        self.reranker = reranker

    def build(self, inputs):
        question = inputs.get("question", "")
        if is_pure_greeting(question):
            return "CHỈ_CHÀO_HỎI_KHÔNG_CÓ_NHU_CẦU_BĐS"
        query = inputs.get("search_query", question)
        start = time.monotonic()
        docs = self.retriever.invoke(query)
        if self.settings.vector_provider == "faiss":
            try:
                current = read_source(self.settings.source_path)
                docs = [d for d in docs if any(r["public"] and r["text"] == d.page_content for r in current.values())]
            except Exception:
                docs = []
                log.warning("retrieval status=degraded reason=source_unavailable")
        candidates = filter_documents(docs, query)[:self.settings.candidate_limit]
        log.info("retrieval candidates=%d elapsed_ms=%.1f", len(candidates), (time.monotonic()-start)*1000)
        ranked = self.reranker.rerank(query, candidates)
        selected, chars = [], 0
        for doc in ranked:
            if chars + len(doc.page_content) + 2 <= self.settings.context_chars:
                selected.append(doc)
                chars += len(doc.page_content) + 2
        return format_docs_with_greeting_check({"docs": selected, "question": question, "search_query": query})
