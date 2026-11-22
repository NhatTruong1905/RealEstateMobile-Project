import argparse
import asyncio
import json
import logging
from pathlib import Path

from dotenv import load_dotenv
from rag.config import Settings
from rag.providers import create_embedding, create_llm
from rag.qdrant_store import QdrantParentStore
from rag.embedding_contract import embedding_contract


def main():
    load_dotenv()
    parser = argparse.ArgumentParser(description="Explicit dev smoke/sync; never runs at API startup")
    parser.add_argument("command", choices=["setup-check", "gemini-smoke", "sync-backend", "qdrant-check", "rerank-check"])
    parser.add_argument("--allow-api-calls", action="store_true", help="Acknowledge configured Gemini calls may incur cost")
    parser.add_argument("--manifest", default="./embedding-smoke.json")
    parser.add_argument("--limit", type=int, default=20)
    parser.add_argument("--max-chunks", type=int, default=100)
    parser.add_argument("--after", type=int, default=0, help="Backend keyset cursor; resume with next_after")
    args = parser.parse_args()
    if not 1 <= args.limit <= 100 or not 1 <= args.max_chunks <= 100 or args.after < 0:
        parser.error("limit/max-chunks must be 1..100")
    if args.command in {"gemini-smoke", "sync-backend"} and not args.allow_api_calls:
        parser.error("Specify --allow-api-calls only after confirming your dev budget")
    store = None
    try:
        settings = Settings.from_env()
        if args.command == "setup-check":
            from rag.setup_check import check_setup
            result = check_setup(settings)
            print(json.dumps(result))
            return 0 if result["status"] == "configured_offline" else 1
        if args.command == "rerank-check":
            from dataclasses import replace
            from langchain_core.documents import Document
            from rag.reranker import Reranker
            reranker = Reranker(replace(settings, rerank_enabled=True, top_n=2))
            try:
                docs = [Document(page_content="A house for sale in Ho Chi Minh City."),
                        Document(page_content="A recipe for chocolate cake.")]
                result = reranker._request("Find a house for sale", docs, settings.timeout)
                print(json.dumps({"status": "ok", "count": len(result), "quality_verified": False}))
                return 0
            finally:
                reranker.close()
        if args.command == "gemini-smoke":
            if settings.llm_provider != "gemini":
                raise ValueError("Smoke requires Gemini profile")
            embedding = create_embedding(settings)
            query = embedding.embed_query("căn hộ thử nghiệm")
            document = embedding.embed_documents(["căn hộ thử nghiệm"])[0]
            if not query or len(query) != len(document):
                raise ValueError("query/document dimensions differ")
            llm = create_llm(settings)
            llm.invoke("Trả lời đúng một từ: chào")
            from api.schemas import RealEstateIntentSummary
            llm.with_structured_output(RealEstateIntentSummary).invoke("Khách tìm căn hộ 2 phòng ngủ.")
            async def stream_check():
                chunks = []
                async for chunk in llm.astream("Trả lời đúng một từ: chào"):
                    chunks.append(chunk)
                if not chunks:
                    raise ValueError("Empty stream")
            asyncio.run(stream_check())
            contract = embedding_contract(settings, len(query))
            path = Path(args.manifest)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(contract, indent=2), encoding="utf-8")
            print(json.dumps({"status": "ok", "llm_model": settings.llm_model, "contract": contract}))
            return 0
        store = QdrantParentStore(settings, create_embedding(settings) if args.command == "sync-backend" else None)
        if args.command == "qdrant-check":
            contract = store.validate()
            print(json.dumps({"status": "ok", "collection": settings.collection, "contract": contract,
                              "points": store.client.count(settings.collection, exact=True).count}))
            return 0
        manifest = Path(args.manifest)
        if manifest.is_file():
            contract = json.loads(manifest.read_text(encoding="utf-8"))
            if contract != embedding_contract(settings, contract["dimension"]):
                raise ValueError("Smoke manifest does not match configuration")
            store.validate(contract, create=True)
        else:
            store.validate()
        rows = store.source.page(args.after, args.limit)
        result = dict(upsert=0, delete=0, skipped=0, failed=0)
        cursor = args.after
        for row in rows:
            try:
                result[store.apply_property(store.source.get(row["id"]), args.max_chunks)] += 1
                cursor = int(row["id"])
            except Exception as exc:
                result["failed"] += 1
                logging.error("sync status=failed reason=%s", type(exc).__name__)
                break
        result.update(next_after=cursor, possibly_more=len(rows) == args.limit)
        print(json.dumps(result))
        return 1 if result["failed"] else 0
    except Exception as exc:
        print(json.dumps({"status": "failed", "reason": type(exc).__name__}))
        return 1
    finally:
        if store:
            store.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    raise SystemExit(main())
