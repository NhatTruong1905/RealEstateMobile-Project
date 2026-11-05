"""Embedding compatibility manifest shared by smoke, indexing and retrieval."""

def embedding_contract(settings, dimension):
    from importlib.metadata import version
    return {"model": settings.embedding_model, "dimension": dimension,
            "query_task": "RETRIEVAL_QUERY", "document_task": "RETRIEVAL_DOCUMENT",
            "normalization": "none-client;cosine-store", "distance": "Cosine",
            "preprocessing": "raw-text-v1", "chunk_size": 450, "chunk_overlap": 50,
            "adapter_version": version("langchain-google-genai"), "revision": 1}
