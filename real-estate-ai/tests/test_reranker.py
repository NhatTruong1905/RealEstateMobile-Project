import json
import threading
import time
from dataclasses import replace
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import httpx
import pytest
from langchain_core.documents import Document
from rag.config import Settings
from rag.reranker import Reranker


DOCS = [Document(page_content=f"document {i}", metadata={"source_id": str(i)}) for i in range(3)]


def client(handler, **kwargs):
    settings = replace(Settings(), rerank_enabled=True, top_n=2, **kwargs)
    return Reranker(settings, httpx.MockTransport(handler))


def test_mapping_payload_and_v1_url():
    def handler(request):
        assert request.url.path == "/v1/rerank"
        payload = json.loads(request.content)
        assert payload["documents"] == [d.page_content for d in DOCS]
        assert payload["top_n"] == 2
        return httpx.Response(200, json={"results": [{"index": 2, "relevance_score": 7}, {"index": 0, "relevance_score": -2}]})
    r = client(handler, rerank_base_url="http://localhost:8001/v1/")
    try:
        result = r.rerank("query", DOCS)
        assert result[0] is DOCS[2] and result[1] is DOCS[0]
        assert result[0].metadata == {"source_id": "2"}
    finally:
        r.close()


@pytest.mark.parametrize("rows", [[], [{"index": 0, "relevance_score": 1}],
    [{"index": i, "relevance_score": s} for i, s in [(0, 1), (0, .5)]],
    [{"index": -1, "relevance_score": 1}, {"index": 0, "relevance_score": .5}],
    [{"index": 3, "relevance_score": 1}, {"index": 0, "relevance_score": .5}],
    [{"index": True, "relevance_score": 1}, {"index": 0, "relevance_score": .5}],
    [{"index": 1.0, "relevance_score": 1}, {"index": 0, "relevance_score": .5}],
    [{"index": 1, "relevance_score": "1"}, {"index": 0, "relevance_score": .5}],
    [{"index": 1, "relevance_score": float("inf")}, {"index": 0, "relevance_score": .5}],
    [{"index": 1, "relevance_score": float("nan")}, {"index": 0, "relevance_score": .5}],
    [{"index": 1}, {"index": 0, "relevance_score": .5}], None])
def test_invalid_response_falls_back_whole_set(rows):
    # Use response text for non-finite numbers (invalid JSON from misbehaving upstream).
    r = client(lambda _: httpx.Response(200, text=json.dumps({"results": rows})))
    try:
        assert r.rerank("query", DOCS) is DOCS
    finally:
        r.close()


@pytest.mark.parametrize("status", [400, 401, 429, 500, 503])
def test_http_errors_no_retry(status):
    calls = []
    r = client(lambda req: (calls.append(req) or httpx.Response(status)))
    try:
        assert r.rerank("query", DOCS) is DOCS
        assert len(calls) == 1
    finally:
        r.close()


@pytest.mark.parametrize("error", [httpx.ConnectError, httpx.ReadTimeout])
def test_network_fallback(error):
    def handler(request):
        raise error("synthetic", request=request)
    r = client(handler)
    try:
        assert r.rerank("query", DOCS) is DOCS
    finally:
        r.close()


def test_disabled_empty_and_small_inputs():
    def fail(_):
        pytest.fail("Unexpected HTTP")
    r = Reranker(Settings(), httpx.MockTransport(fail))
    assert r.rerank("q", DOCS) is DOCS
    r.close()
    r = client(fail)
    assert r.rerank("q", []) == []
    r.close()
    for docs in [DOCS[:1], DOCS[:2]]:
        r = client(lambda _: httpx.Response(200, json={"results": [
            {"index": i, "relevance_score": i} for i in range(len(docs))]}))
        assert r.rerank("q", docs) == docs[::-1]
        r.close()


def test_invalid_json():
    r = client(lambda _: httpx.Response(200, text="<html>broken</html>"))
    assert r.rerank("q", DOCS) is DOCS
    r.close()


def test_real_socket_deadline_and_queue():
    # Exercise real httpx serialization/timeouts, no vendor service or credentials.
    calls = []
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass
        def do_POST(self):
            calls.append(json.loads(self.rfile.read(int(self.headers["Content-Length"]))))
            time.sleep(1.0)
            try:
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'{"results": []}')
            except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
                pass
    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    worker = threading.Thread(target=server.serve_forever, daemon=True)
    worker.start()
    r = Reranker(replace(Settings(), rerank_enabled=True, timeout=.5,
                         rerank_base_url=f"http://127.0.0.1:{server.server_port}"))
    try:
        start = time.monotonic()
        assert r.rerank("q", DOCS) is DOCS
        assert time.monotonic() - start < .8
        assert len(calls) == 1
        assert calls[0]["documents"] == [d.page_content for d in DOCS]
        assert r.slots.acquire(timeout=1)
        try:
            start = time.monotonic()
            assert r.rerank("q", DOCS) is DOCS
            assert time.monotonic() - start < .8
            assert len(calls) == 1
        finally:
            r.slots.release()
    finally:
        r.close()
        server.shutdown()
        server.server_close()
