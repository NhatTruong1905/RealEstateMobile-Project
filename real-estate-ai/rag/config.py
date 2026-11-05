"""Backend-only configuration. Never include credentials in diagnostics."""
import os
from dataclasses import dataclass, field
from urllib.parse import urlsplit


def positive(name, default, cast=int):
    value = cast(os.getenv(name, str(default)))
    import math
    if not math.isfinite(value) or value <= 0:
        raise ValueError(f"{name} must be positive and finite")
    return value


@dataclass(frozen=True)
class Settings:
    llm_provider: str = "gemini"
    google_api_key: str = field(default="", repr=False)
    llm_model: str = ""
    embedding_model: str = "models/gemini-embedding-001"
    vector_provider: str = "qdrant"
    qdrant_url: str = "http://localhost:6333"
    qdrant_api_key: str = field(default="", repr=False)
    collection: str = "realestate_gemini_dev_v1"
    state_path: str = "./vector_database/qdrant-dev.sqlite3"
    source_path: str = ""
    rerank_enabled: bool = False
    rerank_base_url: str = "http://127.0.0.1:8001"
    rerank_model: str = "Qwen/Qwen3-Reranker-0.6B"
    candidate_limit: int = 20
    top_n: int = 5
    timeout: float = 5.0
    concurrency: int = 1
    document_chars: int = 4000
    context_chars: int = 16000
    max_output_tokens: int = 2048

    @classmethod
    def from_env(cls):
        enabled = os.getenv("RERANK_ENABLED", "false").lower()
        if enabled not in {"true", "false"}:
            raise ValueError("RERANK_ENABLED must be true/false")
        settings = cls(
            llm_provider=os.getenv("LLM_PROVIDER", "gemini"),
            google_api_key=os.getenv("GOOGLE_API_KEY", ""),
            llm_model=os.getenv("GEMINI_LLM_MODEL", ""),
            embedding_model=os.getenv("GEMINI_EMBEDDING_MODEL", "models/gemini-embedding-001"),
            vector_provider=os.getenv("VECTOR_STORE_PROVIDER", "qdrant"),
            qdrant_url=os.getenv("QDRANT_URL", "http://localhost:6333"),
            qdrant_api_key=os.getenv("QDRANT_API_KEY", ""),
            collection=os.getenv("QDRANT_COLLECTION", "realestate_gemini_dev_v1"),
            state_path=os.getenv("QDRANT_STATE_PATH", "./vector_database/qdrant-dev.sqlite3"),
            source_path=os.getenv("INDEX_SOURCE_JSON", ""),
            rerank_enabled=enabled == "true",
            rerank_base_url=os.getenv("RERANK_BASE_URL", "http://127.0.0.1:8001"),
            rerank_model=os.getenv("RERANK_MODEL", "Qwen/Qwen3-Reranker-0.6B"),
            candidate_limit=positive("RERANK_CANDIDATE_LIMIT", 20),
            top_n=positive("RERANK_TOP_N", 5),
            timeout=positive("RERANK_TIMEOUT_SECONDS", 5, float),
            concurrency=positive("RERANK_MAX_CONCURRENCY", 1),
            document_chars=positive("RERANK_DOCUMENT_CHARS", 4000),
            context_chars=positive("CONTEXT_MAX_CHARS", 16000),
            max_output_tokens=positive("LLM_MAX_OUTPUT_TOKENS", 2048),
        )
        if settings.llm_provider not in {"gemini", "legacy"}:
            raise ValueError("LLM_PROVIDER must be gemini/legacy")
        if settings.vector_provider not in {"qdrant", "faiss"}:
            raise ValueError("VECTOR_STORE_PROVIDER must be qdrant/faiss")
        if settings.top_n > settings.candidate_limit:
            raise ValueError("RERANK_TOP_N exceeds RERANK_CANDIDATE_LIMIT")
        for name in ("qdrant_url", "rerank_base_url"):
            url = urlsplit(getattr(settings, name))
            if url.scheme not in {"http", "https"} or not url.hostname or url.username or url.password or url.query or url.fragment:
                raise ValueError(f"Invalid {name}")
        return settings


# Compatibility exports for existing callers; new code imports rag.providers.
from rag.providers import create_embedding, create_llm  # noqa: F401,E402
