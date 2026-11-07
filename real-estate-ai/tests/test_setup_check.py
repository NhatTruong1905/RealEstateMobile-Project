import json
from pathlib import Path

from rag.config import Settings
from rag.setup_check import check_setup


def test_setup_reports_missing_fields_without_exposing_secrets(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    result = check_setup(Settings(google_api_key="private-google-key",
                                  qdrant_api_key="private-qdrant-key"))
    output = json.dumps(result)
    assert "private-google-key" not in output
    assert "private-qdrant-key" not in output
    assert result["status"] == "needs_setup"
    assert result["live_services_verified"] is False
    checks = {row["check"]: row["status"] for row in result["checks"]}
    assert checks["google_api_key"] == "ok"
    assert checks["gemini_model"] == "needs_setup"
    assert checks["dev_source"] == "needs_setup"


def test_placeholder_key_is_not_ready_and_configured_state_is_only_offline(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    source = tmp_path / "source.json"
    source.write_text(json.dumps({"kind": "mock", "records": [
        {"id": "1", "version": 1, "public": True, "text": "dev listing"}
    ]}), encoding="utf-8")
    Path("vector_database").mkdir()
    Path("vector_database/embedding-smoke.json").write_text("{}")
    state = tmp_path / "state.sqlite3"
    state.touch()
    settings = Settings(google_api_key="REPLACE_LOCALLY", llm_model="account-model",
                        collection="test_mock", source_path=str(source), state_path=str(state))
    assert check_setup(settings)["status"] == "needs_setup"
    from dataclasses import replace
    result = check_setup(replace(settings, google_api_key="local-only"))
    assert result["status"] == "configured_offline"
    assert result["live_services_verified"] is False


def test_startup_failure_closes_loaded_retriever(monkeypatch):
    from rag import pipeline
    closed = []

    class Store:
        def close(self):
            closed.append(True)

    class LLM:
        def with_structured_output(self, _):
            return object()

    monkeypatch.setattr(pipeline.Settings, "from_env", lambda: Settings())
    monkeypatch.setattr(pipeline, "create_embedding", lambda _: object())
    monkeypatch.setattr(pipeline, "create_llm", lambda _: LLM())
    monkeypatch.setattr(pipeline, "create_retriever", lambda *a, **kw: Store())

    def fail(_):
        raise RuntimeError("reranker init failed")

    monkeypatch.setattr(pipeline, "Reranker", fail)
    import pytest
    with pytest.raises(RuntimeError):
        pipeline.RAGPipeline().initialize()
    assert closed == [True]


def test_invalid_store_is_closed_before_startup_fails():
    from rag.retriever import create_retriever
    closed = []

    class InvalidStore:
        def __init__(self, *args):
            pass

        def validate(self):
            raise ValueError("missing index")

        def close(self):
            closed.append(True)

    import pytest
    with pytest.raises(ValueError):
        create_retriever(Settings(), None, ".", store_factory=InvalidStore)
    assert closed == [True]
