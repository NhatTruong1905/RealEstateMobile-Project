"""One bounded request; invalid responses fall back to original documents."""
import logging
import math
import threading
import time
from concurrent.futures import ThreadPoolExecutor, TimeoutError

import httpx

log = logging.getLogger(__name__)


class Reranker:
    def __init__(self, settings, transport=None):
        self.settings = settings
        self.transport = transport
        self.slots = threading.BoundedSemaphore(settings.concurrency)
        self.executor = ThreadPoolExecutor(max_workers=settings.concurrency, thread_name_prefix="rerank")
        base = settings.rerank_base_url.rstrip("/")
        self.endpoint = base + ("/rerank" if base.endswith("/v1") else "/v1/rerank")

    def _request(self, query, docs, timeout):
        # No redirects/retries: never forward candidate contents to another host.
        with httpx.Client(timeout=timeout, transport=self.transport, trust_env=False) as client:
            response = client.post(self.endpoint, json={
                "model": self.settings.rerank_model, "query": query[:4000],
                "documents": [d.page_content[:self.settings.document_chars] for d in docs],
                "top_n": min(self.settings.top_n, len(docs)),
            })
            response.raise_for_status()
            rows = response.json()["results"]
        expected = min(self.settings.top_n, len(docs))
        if not isinstance(rows, list) or len(rows) != expected:
            raise ValueError("result_count")
        seen = set()
        for row in rows:
            index, score = row["index"], row["relevance_score"]
            if type(index) is not int or not 0 <= index < len(docs) or index in seen:
                raise ValueError("result_index")
            if type(score) not in (int, float) or not math.isfinite(score):
                raise ValueError("result_score")
            seen.add(index)
        return [docs[r["index"]] for r in sorted(rows, key=lambda r: r["relevance_score"], reverse=True)]

    def rerank(self, query, docs):
        if not self.settings.rerank_enabled or not docs:
            return docs
        start = time.monotonic()
        acquired = self.slots.acquire(timeout=self.settings.timeout)
        try:
            if not acquired:
                raise TimeoutError()
            remaining = self.settings.timeout - (time.monotonic() - start)
            if remaining <= 0:
                self.slots.release()
                raise TimeoutError()
            future = self.executor.submit(self._request, query, docs, remaining)
            # Keep slot occupied until the HTTP worker actually ends, even on deadline.
            future.add_done_callback(lambda _: self.slots.release())
            result = future.result(timeout=remaining)
            log.info("rerank status=ok candidates=%d elapsed_ms=%.1f", len(docs), (time.monotonic()-start)*1000)
            return result
        except Exception as exc:
            log.warning("rerank status=degraded reason=%s candidates=%d elapsed_ms=%.1f",
                        type(exc).__name__, len(docs), (time.monotonic()-start)*1000)
            return docs

    def close(self):
        self.executor.shutdown(wait=False, cancel_futures=True)
