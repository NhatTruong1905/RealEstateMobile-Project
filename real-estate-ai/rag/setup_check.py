"""Offline setup diagnostics: no SDK construction, network requests or secret output."""
from pathlib import Path

from rag.config import Settings
from rag.source import read_source


def configured(value):
    value = value.strip()
    return bool(value) and not value.upper().startswith(("REPLACE", "YOUR_", "<"))


def check_setup(settings: Settings):
    checks = []

    def add(name, ok, action):
        checks.append({"check": name, "status": "ok" if ok else "needs_setup",
                       "action": "" if ok else action})

    add("gemini_profile", settings.llm_provider == "gemini", "Set LLM_PROVIDER=gemini")
    add("google_api_key", configured(settings.google_api_key), "Set GOOGLE_API_KEY in backend .env locally")
    add("gemini_model", configured(settings.llm_model), "Set GEMINI_LLM_MODEL to an ID available in your AI Studio project")
    add("qdrant_profile", settings.vector_provider == "qdrant", "Set VECTOR_STORE_PROVIDER=qdrant")
    try:
        source = read_source(settings.source_path)
        valid_source = bool(source)
    except (OSError, ValueError, TypeError, AttributeError):
        valid_source = False
    add("dev_source", valid_source, "Set INDEX_SOURCE_JSON=./data/listings_mock.json")
    add("mock_collection", settings.collection.endswith("_mock"), "Use a separate QDRANT_COLLECTION ending in _mock for fixture data")
    add("embedding_smoke", Path("vector_database/embedding-smoke.json").is_file(),
        "After confirming budget, run python -m rag.dev gemini-smoke --allow-api-calls")
    add("parent_state", Path(settings.state_path).is_file(),
        "After smoke succeeds and Qdrant is running, run the bounded sync command")
    return {"status": "configured_offline" if all(c["status"] == "ok" for c in checks) else "needs_setup",
            "checks": checks, "live_services_verified": False,
            "rerank": "enabled_requires_live_smoke" if settings.rerank_enabled else "disabled"}
