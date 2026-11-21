from pathlib import Path

from rag.config import Settings


def configured(value):
    value = value.strip()
    return bool(value) and not value.upper().startswith(("REPLACE", "YOUR_", "<"))


def check_setup(settings: Settings):
    checks = []

    def add(name, ok, action):
        checks.append({"check": name, "status": "ok" if ok else "needs_setup",
                       "action": "" if ok else action})

    add("gemini_profile", settings.llm_provider == "gemini", "Set LLM_PROVIDER=gemini")
    add("google_api_key", configured(settings.google_llm_api_key or settings.google_api_key) and
        configured(settings.google_embedding_api_key or settings.google_api_key), "Set GOOGLE_API_KEY or separate GOOGLE_LLM_API_KEY / GOOGLE_EMBEDDING_API_KEY locally")
    add("gemini_model", configured(settings.llm_model), "Set GEMINI_LLM_MODEL to an ID available in your AI Studio project")
    add("qdrant_profile", settings.vector_provider == "qdrant", "Set VECTOR_STORE_PROVIDER=qdrant")
    add("backend_source", configured(settings.property_api_token), "Set PROPERTY_API_TOKEN and PROPERTY_API_URL")
    add("live_collection", not settings.collection.endswith("_mock"), "Use a non-mock collection for real properties")
    from rag.messaging import BrokerSettings
    try:
        BrokerSettings.from_env()
        valid_broker = True
    except ValueError:
        valid_broker = False
    add("rabbitmq_config", valid_broker, "Set RABBITMQ_URL; this offline check does not connect")
    if settings.qdrant_url.startswith("https://"):
        add("qdrant_cloud_key", configured(settings.qdrant_api_key), "Set cluster Database API key, not management key")
    add("embedding_smoke", Path("vector_database/embedding-smoke.json").is_file(),
        "After confirming budget, run python -m rag.dev gemini-smoke --allow-api-calls")
    add("parent_state", Path(settings.state_path).is_file(),
        "After smoke succeeds and Qdrant is running, run the bounded sync command")
    return {"status": "configured_offline" if all(c["status"] == "ok" for c in checks) else "needs_setup",
            "checks": checks, "live_services_verified": False,
            "rerank": "enabled_requires_live_smoke" if settings.rerank_enabled else "disabled"}
