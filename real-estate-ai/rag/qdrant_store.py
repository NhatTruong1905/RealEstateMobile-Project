import hashlib
import json
import logging
import sqlite3
import uuid
from contextlib import contextmanager
from pathlib import Path

from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from qdrant_client import QdrantClient, models

from rag.source import read_source
from rag.embedding_contract import embedding_contract

log = logging.getLogger(__name__)


def digest(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()






class QdrantParentStore:
    def __init__(self, settings, embedding, client=None):
        self.settings, self.embedding = settings, embedding
        self.client = client or QdrantClient(url=settings.qdrant_url,
                                            api_key=settings.qdrant_api_key or None, timeout=10)
        Path(settings.state_path).parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as db:
            db.execute("CREATE TABLE IF NOT EXISTS manifest (id INTEGER PRIMARY KEY CHECK(id=1), value TEXT NOT NULL)")
            db.execute("CREATE TABLE IF NOT EXISTS parents (id TEXT PRIMARY KEY, version INTEGER NOT NULL, hash TEXT NOT NULL, document TEXT NOT NULL, points TEXT NOT NULL, public INTEGER NOT NULL)")
        self.splitter = RecursiveCharacterTextSplitter(chunk_size=450, chunk_overlap=50)

    @contextmanager
    def connect(self):
        connection = sqlite3.connect(self.settings.state_path, timeout=30)
        try:
            with connection:
                yield connection
        finally:
            connection.close()

    def validate(self, contract=None, create=False):
        with self.connect() as db:
            saved = db.execute("SELECT value FROM manifest WHERE id=1").fetchone()
        if saved:
            existing = json.loads(saved[0])
            if existing.get("collection") != self.settings.collection:
                raise ValueError("State belongs to a different collection")
            expected = embedding_contract(self.settings, existing["contract"]["dimension"])
            if existing["contract"] != expected or (contract is not None and contract != expected):
                raise ValueError("Embedding contract mismatch; use a separate collection AND state file")
            contract = expected
        elif not create or contract is None:
            raise ValueError("Index missing; run explicit sync after embedding smoke")
        exists = self.client.collection_exists(self.settings.collection)
        if exists:
            vectors = self.client.get_collection(self.settings.collection).config.params.vectors
            if not isinstance(vectors, models.VectorParams) or vectors.size != contract["dimension"] or vectors.distance != models.Distance.COSINE:
                raise ValueError("Qdrant schema mismatch")
            if not saved:
                raise ValueError("Existing collection has no matching local manifest; refusing adoption")
        elif create and not saved:
            self.client.create_collection(self.settings.collection, vectors_config=models.VectorParams(
                size=contract["dimension"], distance=models.Distance.COSINE))
        else:
            raise ValueError("Qdrant collection missing; refusing automatic rebuild")
        if not saved:
            with self.connect() as db:
                db.execute("INSERT INTO manifest VALUES (1, ?)", (json.dumps({
                    "collection": self.settings.collection, "contract": contract}),))
        return contract

    def sync(self, records, limit=20, max_chunks=100, offset=0):
        if not self.settings.collection.endswith("_mock"):
            raise ValueError("Mock data requires a collection ending in _mock")
        result = dict(upsert=0, delete=0, skipped=0, failed=0)
        for row in list(records.values())[offset:offset + limit]:
            try:
                self._sync_one(row, max_chunks)
                result[self.last_action] += 1
            except Exception as exc:
                result["failed"] += 1
                log.error("sync status=failed reason=%s", type(exc).__name__)
        return result

    def _sync_one(self, row, max_chunks):
        pid, version = row["id"], row["version"]
        text = row.get("text", "")
        content_hash = digest(text)
        document = json.dumps({"text": text, "metadata": {**row.get("metadata", {}),
                               "source_id": pid, "source_kind": "mock", "source_version": version}}, ensure_ascii=False)
        with self.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            old = db.execute("SELECT version, hash, document, points, public FROM parents WHERE id=?", (pid,)).fetchone()
            if old and version <= old[0]:
                if version == old[0] and (content_hash != old[1] or bool(row["public"]) != bool(old[4]) or document != old[2]):
                    raise ValueError("Changed record must increment version")
                self.last_action = "skipped"
                return
            old_points = json.loads(old[3]) if old else []
            points = []
            if row["public"]:
                if old and old[4] and content_hash == old[1]:
                    points = old_points  # metadata-only update: zero embedding calls
                else:
                    chunks = self.splitter.split_text(text)
                    if len(chunks) > max_chunks:
                        raise ValueError("Record exceeds chunk budget")
                    vectors = self.embedding.embed_documents(chunks)
                    with self.connect() as manifest_db:
                        contract = json.loads(manifest_db.execute("SELECT value FROM manifest WHERE id=1").fetchone()[0])["contract"]
                    if len(vectors) != len(chunks) or any(len(v) != contract["dimension"] for v in vectors):
                        raise ValueError("Embedding dimensions/count mismatch")
                    points = [str(uuid.uuid5(uuid.NAMESPACE_URL, f"{self.settings.collection}:{pid}:{content_hash}:{i}")) for i in range(len(chunks))]
                    self.client.upsert(self.settings.collection, points=[models.PointStruct(
                        id=point, vector=vector, payload={"parent_id": pid, "content_hash": content_hash,
                                                        "chunk": chunk, "source_kind": "mock"})
                        for point, vector, chunk in zip(points, vectors, chunks)], wait=True)
            db.execute("INSERT OR REPLACE INTO parents VALUES (?, ?, ?, ?, ?, ?)",
                       (pid, version, content_hash, document, json.dumps(points), int(row["public"])))
        stale_filter = models.Filter(must=[models.FieldCondition(key="parent_id", match=models.MatchValue(value=pid))],
                                    must_not=[models.HasIdCondition(has_id=points)] if points else None)
        self.client.delete(self.settings.collection, points_selector=models.FilterSelector(filter=stale_filter), wait=True)
        self.last_action = "upsert" if row["public"] else "delete"

    def invoke(self, query):
        try:
            source = read_source(self.settings.source_path)
        except Exception:
            log.warning("retrieval status=degraded reason=source_unavailable")
            return []
        vector = self.embedding.embed_query(query)
        hits = self.client.query_points(self.settings.collection, query=vector,
                                       limit=max(25, self.settings.candidate_limit * 5), with_payload=True).points
        documents, seen = [], set()
        with self.connect() as db:
            for hit in hits:
                pid = (hit.payload or {}).get("parent_id")
                if pid in seen:
                    continue
                row = db.execute("SELECT version, hash, document, points, public FROM parents WHERE id=?", (pid,)).fetchone()
                current = source.get(pid)
                if not row or not row[4] or not current or not current["public"]:
                    continue
                if current["version"] != row[0] or digest(current["text"]) != row[1] or str(hit.id) not in json.loads(row[3]):
                    continue
                stored = json.loads(row[2])
                if stored["metadata"] != {**current.get("metadata", {}), "source_id": pid, "source_kind": "mock", "source_version": current["version"]}:
                    continue
                seen.add(pid)
                documents.append(Document(page_content=stored["text"], metadata=stored["metadata"]))
        return documents

    def close(self):
        self.client.close()
