import copy
import json
from dataclasses import replace

import pytest
from qdrant_client import QdrantClient
from rag.config import Settings
from rag.qdrant_store import QdrantParentStore, embedding_contract, read_source


class FakeEmbedding:
    def __init__(self):
        self.calls = 0
        self.fail = False
    def embed_documents(self, texts):
        self.calls += 1
        if self.fail:
            raise RuntimeError("synthetic embedding error")
        return [[1.0, float(len(t) % 11 + 1), 0.5] for t in texts]
    def embed_query(self, query):
        return [1.0, 1.0, 0.5]


@pytest.fixture
def setup(tmp_path):
    records = read_source("tests/fixtures/listings_mock.json")
    path = tmp_path / "source.json"
    path.write_text(json.dumps({"kind": "mock", "records": list(records.values())}), encoding="utf-8")
    settings = replace(Settings(), collection="integration_mock", state_path=str(tmp_path / "parents.sqlite"), source_path=str(path))
    embedding = FakeEmbedding()
    store = QdrantParentStore(settings, embedding, QdrantClient(path=str(tmp_path / "qdrant")))
    store.validate(embedding_contract(settings, 3), create=True)
    yield store, embedding, records, settings, tmp_path
    store.close()


def publish(settings, records):
    from pathlib import Path
    Path(settings.source_path).write_text(json.dumps({"kind": "mock", "records": list(records.values())}), encoding="utf-8")


def test_sync_idempotent_metadata_update_content_delete_restart(setup):
    store, embedding, records, settings, tmp = setup
    assert store.sync(records) == {"upsert": 2, "delete": 1, "skipped": 0, "failed": 0}
    count = store.client.count(settings.collection).count
    calls = embedding.calls
    assert len(store.invoke("căn hộ")) == 2
    assert store.sync(records)["skipped"] == 3
    assert embedding.calls == calls
    assert store.client.count(settings.collection).count == count
    records["mock-1"]["version"] += 1
    records["mock-1"]["metadata"]["new"] = "metadata-only"
    publish(settings, records)
    assert store.sync(records)["upsert"] == 1
    assert embedding.calls == calls
    assert any(d.metadata.get("new") == "metadata-only" for d in store.invoke("q"))
    records["mock-1"]["version"] += 1
    records["mock-1"]["text"] += "\nNội dung đã cập nhật"
    publish(settings, records)
    assert store.sync(records)["upsert"] == 1
    assert embedding.calls == calls + 1
    assert store.client.count(settings.collection).count == count
    assert any("đã cập nhật" in d.page_content for d in store.invoke("q"))
    old = copy.deepcopy(records)
    records["mock-1"]["version"] += 1
    records["mock-1"]["public"] = False
    publish(settings, records)
    assert all(d.metadata["source_id"] != "mock-1" for d in store.invoke("q"))
    assert store.sync(records)["delete"] == 1
    assert store.sync(old)["skipped"] == 3
    store.close()
    restarted = QdrantParentStore(settings, embedding, QdrantClient(path=str(tmp / "qdrant")))
    try:
        restarted.validate()
        assert [d.metadata["source_id"] for d in restarted.invoke("q")] == ["mock-2"]
        assert restarted.sync(old)["skipped"] == 3
    finally:
        restarted.close()


def test_source_unavailable_private_stale_and_missing_batch(setup):
    store, _, records, settings, _ = setup
    store.sync(records)
    records.pop("mock-1")
    assert store.sync({})["delete"] == 0
    assert store.client.count(settings.collection).count == 2
    publish(settings, records)
    assert len(store.invoke("q")) == 1
    records["mock-2"]["text"] += " edited without sync"
    publish(settings, records)
    assert store.invoke("q") == []
    from pathlib import Path
    Path(settings.source_path).unlink()
    assert store.invoke("q") == []


def test_partial_failure_retry_and_stale_versions(setup):
    store, embedding, records, settings, _ = setup
    embedding.fail = True
    result = store.sync(records)
    assert result["failed"] == 2 and result["delete"] == 1
    embedding.fail = False
    assert store.sync(records)["failed"] == 0
    records["mock-1"]["text"] += " conflict"
    assert store.sync(records)["failed"] == 1
    changed = replace(settings, embedding_model="different-model")
    other = QdrantParentStore(changed, embedding, store.client)
    with pytest.raises(ValueError, match="contract mismatch"):
        other.validate()


def test_schema_manifest_and_mock_isolation(setup):
    store, embedding, records, settings, tmp = setup
    with pytest.raises(ValueError, match="contract mismatch"):
        store.validate(embedding_contract(settings, 4))
    bad = QdrantParentStore(replace(settings, state_path=str(tmp / "other.sqlite")), embedding, store.client)
    with pytest.raises(ValueError, match="refusing adoption"):
        bad.validate(embedding_contract(settings, 3), create=True)
    real = QdrantParentStore(replace(settings, collection="production"), embedding, store.client)
    with pytest.raises(ValueError, match="_mock"):
        real.sync(records)


def test_changed_long_parent_mapping_and_chunk_budget(setup):
    store, _, records, settings, _ = setup
    records["mock-1"]["text"] = "Long parent content. " * 300
    publish(settings, records)
    assert store.sync(records, max_chunks=1)["failed"] == 1
    assert store.sync(records)["failed"] == 0
    docs = store.invoke("q")
    assert len(docs) == 2
    assert next(d for d in docs if d.metadata["source_id"] == "mock-1").page_content == records["mock-1"]["text"]


def test_qdrant_write_failure_does_not_commit_parent(setup, monkeypatch):
    store, _, records, settings, _ = setup
    original = store.client.upsert
    def fail(*args, **kwargs):
        raise RuntimeError("synthetic Qdrant error")
    monkeypatch.setattr(store.client, "upsert", fail)
    assert store.sync(records)["failed"] == 2
    assert store.invoke("q") == []
    monkeypatch.setattr(store.client, "upsert", original)
    assert store.sync(records)["upsert"] == 2
    assert len(store.invoke("q")) == 2
