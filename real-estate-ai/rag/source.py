"""Validate the explicit dev listing source; real authorization needs its own adapter."""
import json
from pathlib import Path

def read_source(path):
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    if data.get("kind") != "mock" or not isinstance(data.get("records"), list):
        raise ValueError("Only explicit mock sources supported until live listing authorization is connected")
    seen = set()
    for row in data["records"]:
        if not isinstance(row.get("id"), str) or not row["id"] or row["id"] in seen:
            raise ValueError("Source requires unique string IDs")
        seen.add(row["id"])
        if type(row.get("version")) is not int or row["version"] < 1 or type(row.get("public")) is not bool:
            raise ValueError("Source requires positive version and public boolean")
        if not isinstance(row.get("text", ""), str) or not isinstance(row.get("metadata", {}), dict):
            raise ValueError("Invalid source text/metadata")
        if row["public"] and not row.get("text", "").strip():
            raise ValueError("Public source text is empty")
    return {r["id"]: r for r in data["records"]}
