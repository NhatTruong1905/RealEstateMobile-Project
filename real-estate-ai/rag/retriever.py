import os
import pickle
from langchain_text_splitters import RecursiveCharacterTextSplitter
from rag.qdrant_store import QdrantParentStore


def create_retriever(settings, embedding, db_dir, store_factory=QdrantParentStore):
    if settings.vector_provider == "qdrant":
        store = store_factory(settings, embedding)
        try:
            store.validate()
        except Exception:
            store.close()
            raise
        return store

    from langchain_community.vectorstores import FAISS
    from langchain_classic.retrievers import ParentDocumentRetriever
    from langchain_core.stores import InMemoryStore

    MARKDOWN_SEPARATORS = [
        r"\n- \*\*Property ID ",
        r"\n- \*\*Property ID",
        r"\n#{1,6} ",
        r"```\n",
        r"\n\*{3,}\n",
        r"\n---+\n",
        r"\n___+\n",
        "\n\n",
        "\n",
        " ",
        ""
    ]

    parent_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1200,
        chunk_overlap=0,
        add_start_index=True,
        strip_whitespace=True,
        is_separator_regex=True,
        separators=MARKDOWN_SEPARATORS,
    )

    child_splitter = RecursiveCharacterTextSplitter(
        chunk_size=450,
        chunk_overlap=50
    )

    docstore_path = os.path.join(str(db_dir), "docstore.pkl")
    faiss_index_path = os.path.join(str(db_dir), "index.faiss")

    if settings.embedding_model != "models/gemini-embedding-001":
        raise ValueError("Legacy FAISS requires its original embedding model")
    if not (os.path.exists(faiss_index_path) and os.path.exists(docstore_path)):
        raise ValueError("FAISS index missing; startup never performs paid indexing")
    vectorstore = FAISS.load_local(folder_path=str(db_dir), embeddings=embedding,
                                  allow_dangerous_deserialization=True)
    docstore = InMemoryStore()
    with open(docstore_path, "rb") as f:
        docstore.mset(list(pickle.load(f).items()))
    return ParentDocumentRetriever(
        vectorstore=vectorstore, docstore=docstore,
        child_splitter=child_splitter, parent_splitter=parent_splitter,
        search_kwargs={"k": 100})
