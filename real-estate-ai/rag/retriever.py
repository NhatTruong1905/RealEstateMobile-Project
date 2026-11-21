from rag.qdrant_store import QdrantParentStore


def create_retriever(settings, embedding, store_factory=QdrantParentStore):
    store = store_factory(settings, embedding)
    try:
        store.validate()
    except Exception:
        store.close()
        raise
    return store
