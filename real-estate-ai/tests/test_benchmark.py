import json
from rag.benchmark import ndcg


def test_ndcg_and_labeled_fixture():
    assert ndcg(["a", "b"], {"a": 3, "b": 1}) == 1
    assert ndcg(["b", "a"], {"a": 3, "b": 1}) < 1
    data = json.load(open("tests/fixtures/rerank_eval_mock.json", encoding="utf-8"))
    assert len(data["queries"]) >= 20
    ids = {r["id"] for r in data["candidates"]}
    assert all(set(q["relevance"]).issubset(ids) for q in data["queries"])
