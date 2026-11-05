"""Labeled fixed-candidate comparison; no Gemini calls. Requires a real reranker."""
import argparse
import json
import math
import statistics
import time
from pathlib import Path
from dotenv import load_dotenv
from langchain_core.documents import Document
from rag.config import Settings
from rag.filters import filter_documents
from rag.reranker import Reranker


def ndcg(ids, labels, k=5):
    def dcg(grades):
        return sum((2 ** grade - 1) / math.log2(i + 2) for i, grade in enumerate(grades[:k]))
    ideal = dcg(sorted(labels.values(), reverse=True))
    return dcg([labels.get(i, 0) for i in ids]) / ideal if ideal else 0.0


def main():
    load_dotenv()
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", default="data/rerank_eval_mock.json")
    args = parser.parse_args()
    settings = Settings.from_env()
    if not settings.rerank_enabled:
        parser.error("Set RERANK_ENABLED=true after real vLLM smoke")
    data = json.loads(Path(args.dataset).read_text(encoding="utf-8"))
    documents = [Document(page_content=r["text"], metadata={"source_id": r["id"]}) for r in data["candidates"]]
    reranker = Reranker(settings)
    off, on, elapsed, failed = [], [], [], 0
    try:
        for case in data["queries"]:
            docs = filter_documents(documents, case["query"])[:settings.candidate_limit]
            labels = case["relevance"]
            off.append(ndcg([d.metadata["source_id"] for d in docs], labels))
            start = time.monotonic()
            try:
                # Fail visibly rather than counting a degraded fallback as model evidence.
                ranked = reranker._request(case["query"], docs, settings.timeout)
                on.append(ndcg([d.metadata["source_id"] for d in ranked], labels))
                elapsed.append((time.monotonic() - start) * 1000)
            except Exception:
                failed += 1
        print(json.dumps({"dataset_kind": data["kind"], "queries": len(off), "failed": failed,
                          "ndcg5_off": statistics.mean(off),
                          "ndcg5_on": statistics.mean(on) if on else None,
                          "warm_median_ms": statistics.median(elapsed[1:]) if len(elapsed) > 1 else None,
                          "first_request_ms": elapsed[0] if elapsed else None,
                          "model": settings.rerank_model}))
        return 1 if failed else 0
    finally:
        reranker.close()


if __name__ == "__main__":
    raise SystemExit(main())
