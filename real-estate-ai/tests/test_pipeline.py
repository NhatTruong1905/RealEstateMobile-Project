import asyncio
import time
from dataclasses import replace

import httpx
import pytest
from fastapi.testclient import TestClient
from langchain_core.documents import Document
from langchain_core.language_models.fake_chat_models import FakeListChatModel
from langchain_core.runnables import RunnableLambda

from api.schemas import RealEstateIntentSummary
from rag import pipeline
from rag.config import Settings, create_llm
from rag.pipeline import RAGPipeline, filter_documents, sanitize_and_budget_history
from rag.reranker import Reranker


def doc(pid, price="2 tỷ", transaction="Bán"):
    return Document(page_content=f"Property ID {pid}: {transaction} căn hộ\nMức giá: {price}", metadata={"source_id": str(pid)})


def test_filters_before_rerank_and_fallback():
    docs = [doc(1), doc(1), doc(2, "4 tỷ"), doc(3, "10 triệu", "Cho thuê"), doc(4)]
    p = RAGPipeline()
    p.settings = replace(Settings(), rerank_enabled=True)
    p.retriever = RunnableLambda(lambda _: docs)
    seen = []
    def handler(request):
        import json
        seen.append(json.loads(request.content)["documents"])
        return httpx.Response(503)
    p.reranker = Reranker(p.settings, httpx.MockTransport(handler))
    try:
        context = p.get_context_for_chain({"question": "mua dưới 3 tỷ"})
        assert seen == [[docs[0].page_content, docs[4].page_content]]
        assert context.count("Property ID 1:") == 1
        assert "Property ID 2:" not in context and "Property ID 3:" not in context
        seen.clear()
        p.get_context_for_chain({"question": "xin chào"})
        assert seen == []
    finally:
        p.close()


class FakeGemini(FakeListChatModel):
    def with_structured_output(self, schema, **kwargs):
        assert schema is RealEstateIntentSummary
        return RunnableLambda(lambda _: RealEstateIntentSummary(location="Quận 7", budget_vnd=3e9))


@pytest.fixture
def initialized(monkeypatch):
    settings = Settings(google_api_key="fake", llm_model="fake-model")
    class FakeStore:
        def __init__(self, *args):
            pass
        def validate(self):
            pass
        def invoke(self, query):
            return [doc(1)]
        def close(self):
            pass
    monkeypatch.setattr(pipeline.Settings, "from_env", lambda: settings)
    monkeypatch.setattr(pipeline, "create_embedding", lambda _: object())
    monkeypatch.setattr(pipeline, "create_llm", lambda _: FakeGemini(responses=["Dạ, căn hộ phù hợp."]))
    monkeypatch.setattr(pipeline, "QdrantParentStore", FakeStore)
    p = RAGPipeline()
    p.initialize()
    yield p
    p.close()


def test_sync_stream_intent_and_history(initialized):
    p = initialized
    assert p.query("mua nhà dưới 3 tỷ") == "Dạ, căn hộ phù hợp."
    history = [{"role": "user", "content": "mua nhà Quận 7"}] * 5
    assert "Quận 7" in p._prepare_inputs("dưới 3 tỷ", history)["search_query"]
    assert p._extract_intent_from_history(history).budget_vnd == 3e9
    async def run():
        result = ""
        async for chunk in p.query_astream("mua nhà dưới 3 tỷ", history):
            result += chunk
        return result
    assert asyncio.run(run()) == "Dạ, căn hộ phù hợp."


def test_stream_does_not_block_event_loop(initialized, monkeypatch):
    original = initialized._prepare_inputs
    def slow(*args):
        time.sleep(.15)
        return original(*args)
    monkeypatch.setattr(initialized, "_prepare_inputs", slow)
    async def run():
        ticks = []
        async def ticker():
            await asyncio.sleep(.03)
            ticks.append(time.monotonic())
        async def consume():
            async for _ in initialized.query_astream("mua nhà"):
                pass
        start = time.monotonic()
        await asyncio.gather(consume(), ticker())
        assert ticks[0] - start < .12
    asyncio.run(run())


def test_public_api_contract(initialized, monkeypatch):
    import main
    import api.routes as routes
    monkeypatch.setattr(routes, "rag_service", initialized)
    # TestClient without context avoids a second lifespan initialization.
    client = TestClient(main.app)
    response = client.post("/api/chat-rag", json={"question": "mua nhà"})
    assert response.status_code == 200 and response.json() == {"answer": "Dạ, căn hộ phù hợp."}
    streamed = client.post("/api/chat-rag/stream", json={"question": "mua nhà"})
    assert streamed.text == "Dạ, căn hộ phù hợp."
    assert client.post("/api/chat-rag", json={"question": " "}).status_code == 400
    def fail(*args, **kwargs):
        raise RuntimeError("secret upstream content")
    monkeypatch.setattr(initialized, "query", fail)
    assert "secret" not in client.post("/api/chat-rag", json={"question": "mua"}).text


def test_gemini_provider_no_legacy_key(monkeypatch):
    from langchain_google_genai import ChatGoogleGenerativeAI
    monkeypatch.delenv("AI_API_KEY", raising=False)
    monkeypatch.delenv("AI_MODEL", raising=False)
    captured = {}
    def fake(**kwargs):
        captured.update(kwargs)
        return object()
    monkeypatch.setattr("langchain_google_genai.ChatGoogleGenerativeAI", fake)
    create_llm(Settings(google_api_key="fake", llm_model="account-verified"))
    assert captured["model"] == "account-verified" and captured["retries"] == 0
    assert "base_url" not in captured
    with pytest.raises(ValueError):
        create_llm(Settings())


@pytest.mark.parametrize("name,value", [("RERANK_ENABLED", "yes"), ("RERANK_TOP_N", "21"),
    ("RERANK_TIMEOUT_SECONDS", "nan"), ("RERANK_CANDIDATE_LIMIT", "0"),
    ("LLM_PROVIDER", "guess"), ("VECTOR_STORE_PROVIDER", "guess"),
    ("RERANK_BASE_URL", "file:///tmp/x")])
def test_config_validation(monkeypatch, name, value):
    monkeypatch.setenv(name, value)
    with pytest.raises(ValueError):
        Settings.from_env()


def test_history_bound():
    history = sanitize_and_budget_history([{"role": "user", "content": "x" * 5000}])
    assert len(history[0]["content"]) <= 1200
