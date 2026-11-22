import hashlib
import json
import logging
import uuid

from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from qdrant_client import QdrantClient, models

from rag.property_source import PropertySource, validate_record
from rag.embedding_contract import embedding_contract
from rag.index_state import IndexState

log = logging.getLogger(__name__)


def digest(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()






class QdrantParentStore:
    def __init__(self, settings, embedding, client=None):
        self.settings, self.embedding = settings, embedding
        self.source = PropertySource(settings)
        self.client = client or QdrantClient(url=settings.qdrant_url,
                                            api_key=settings.qdrant_api_key or None, timeout=10)
        self.state = IndexState(settings)
        self.state.initialize()
        self.splitter = RecursiveCharacterTextSplitter(chunk_size=450, chunk_overlap=50)

    def validate(self, contract=None, create=False):
        with self.state.connect() as db:
            saved = self.state.execute(db, "SELECT value FROM manifest WHERE id=1").fetchone()
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
            self.client.create_payload_index(self.settings.collection, field_name="parent_id",
                                             field_schema=models.PayloadSchemaType.KEYWORD, wait=True)
        else:
            raise ValueError("Qdrant collection missing; refusing automatic rebuild")
        if not saved:
            with self.state.connect() as db:
                self.state.execute(db, "INSERT INTO manifest VALUES (1, ?)", (json.dumps({
                    "collection": self.settings.collection, "contract": contract}),))
        return contract

    def apply_property(self, row, max_chunks=100):
        if self.settings.source_provider != "backend" or self.settings.collection.endswith("_mock"):
            raise ValueError("Live indexing requires backend source and a non-mock collection")
        validate_record(row)
        self._sync_one(row, max_chunks, source_kind="backend")
        return self.last_action

    def _delete_stale(self, pid, points):
        stale_filter = models.Filter(must=[models.FieldCondition(key="parent_id", match=models.MatchValue(value=pid))],
                                    must_not=[models.HasIdCondition(has_id=points)] if points else None)
        self.client.delete(self.settings.collection, points_selector=models.FilterSelector(filter=stale_filter), wait=True)

    def _sync_one(self, row, max_chunks, source_kind):
        pid, version = row["id"], row["version"]
        text = row.get("text", "")
        content_hash = digest(text)
        document = json.dumps({"text": text, "metadata": {**row.get("metadata", {}),
                               "source_id": pid, "source_kind": source_kind, "source_version": version}}, ensure_ascii=False)
        with self.state.connect() as db:
            self.state.lock_property(db, pid)
            old = self.state.execute(db, "SELECT version, hash, document, points, public FROM parents WHERE id=?", (pid,)).fetchone()
            if old and version <= old[0]:
                if version == old[0] and (content_hash != old[1] or bool(row["public"]) != bool(old[4]) or document != old[2]):
                    raise ValueError("Changed record must increment version")
                self.last_action = "skipped"
                self._delete_stale(pid, json.loads(old[3]))
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
                    contract = json.loads(self.state.execute(
                        db, "SELECT value FROM manifest WHERE id=1").fetchone()[0])["contract"]
                    if len(vectors) != len(chunks) or any(len(v) != contract["dimension"] for v in vectors):
                        raise ValueError("Embedding dimensions/count mismatch")
                    points = [str(uuid.uuid5(uuid.NAMESPACE_URL, f"{self.settings.collection}:{pid}:{content_hash}:{i}")) for i in range(len(chunks))]
                    self.client.upsert(self.settings.collection, points=[models.PointStruct(
                        id=point, vector=vector, payload={"parent_id": pid, "content_hash": content_hash,
                                                        "chunk": chunk, "source_kind": source_kind})
                        for point, vector, chunk in zip(points, vectors, chunks)], wait=True)
            self.state.execute(db, "INSERT INTO parents VALUES (?, ?, ?, ?, ?, ?) "
                               "ON CONFLICT(id) DO UPDATE SET version=excluded.version, hash=excluded.hash, "
                               "document=excluded.document, points=excluded.points, public=excluded.public",
                               (pid, version, content_hash, document, json.dumps(points), int(row["public"])))
            self._delete_stale(pid, points)
        self.last_action = "upsert" if row["public"] else "delete"

    def invoke(self, query):
        vector = self.embedding.embed_query(query)
        hits = self.client.query_points(self.settings.collection, query=vector,
                                       limit=max(25, self.settings.candidate_limit * 5), with_payload=True).points
        try:
            source = self.source.get_many([(h.payload or {}).get("parent_id") for h in hits])
        except Exception:
            log.warning("retrieval status=degraded reason=source_unavailable")
            return []
        if not source:
            return []
        placeholders = ", ".join("?" for _ in source)
        with self.state.connect() as db:
            rows = self.state.execute(
                db, f"SELECT id, version, hash, document, points, public FROM parents WHERE id IN ({placeholders})",
                tuple(source),
            ).fetchall()
        parents = {row[0]: row[1:] for row in rows}
        documents, seen = [], set()
        for hit in hits:
            pid = (hit.payload or {}).get("parent_id")
            if pid in seen:
                continue
            row, current = parents.get(pid), source.get(pid)
            if not row or not row[4] or not current or not current["public"]:
                continue
            if current["version"] != row[0] or digest(current["text"]) != row[1] or str(hit.id) not in json.loads(row[3]):
                continue
            stored = json.loads(row[2])
            if stored["metadata"] != {**current.get("metadata", {}), "source_id": pid, "source_kind": self.settings.source_provider, "source_version": current["version"]}:
                continue
            seen.add(pid)
            documents.append(Document(page_content=stored["text"], metadata=stored["metadata"]))
        return documents

    def close(self):
        self.client.close()
