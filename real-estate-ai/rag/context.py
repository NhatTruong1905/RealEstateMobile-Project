import logging
import time
from rag.filters import is_pure_greeting
from rag.ranking import fuse_lexical_candidates

log = logging.getLogger(__name__)

class ContextBuilder:
    def __init__(self, settings, retriever, reranker):
        self.settings = settings
        self.retriever = retriever
        self.reranker = reranker

    def build(self, inputs):
        question = inputs.get("question", "")
        if is_pure_greeting(question):
            return "CHỈ_CHÀO_HỎI_KHÔNG_CÓ_NHU_CẦU_BĐS", []
        reference = inputs.get("property_reference")
        if reference is not None:
            docs = self.retriever.invoke(question, property_id=reference) if reference else []
            if not docs:
                return "KHÔNG_XÁC_NHẬN_ĐƯỢC_TIN_THAM_CHIẾU", []
            return docs[0].page_content[:self.settings.context_chars], docs
        query = inputs.get("search_query", question)
        start = time.monotonic()
        docs = (
            self.retriever.invoke(query, lexical_query=question)
            if self.settings.postgres_lexical else self.retriever.invoke(query)
        )
        candidates = [doc for doc in docs if inputs["criteria"].matches(doc.metadata)]
        if self.settings.lexical_fusion and not self.settings.postgres_lexical:
            candidates = fuse_lexical_candidates(question, candidates)
        candidates = candidates[:self.settings.candidate_limit]
        log.info("retrieval candidates=%d elapsed_ms=%.1f", len(candidates), (time.monotonic()-start)*1000)
        ranked = self.reranker.rerank(query, candidates)
        selected, chars = [], 0
        for doc in ranked[:self.settings.top_n]:
            if chars + len(doc.page_content) + 2 <= self.settings.context_chars:
                selected.append(doc)
                chars += len(doc.page_content) + 2
        if not selected:
            return "KHÔNG_CÓ_BĐS_PHÙ_HỢP_TRONG_KẾT_QUẢ_TÌM_KIẾM", []
        return "\n\n".join(doc.page_content for doc in selected), selected
