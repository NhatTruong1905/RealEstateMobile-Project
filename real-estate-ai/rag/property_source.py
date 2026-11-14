import re
import httpx
from rag.source import read_source


def validate_record(row):
    if not isinstance(row, dict) or not isinstance(row.get("id"), str) or not row["id"]:
        raise ValueError("Invalid property ID")
    if type(row.get("version")) is not int or row["version"] < 1 or type(row.get("public")) is not bool:
        raise ValueError("Invalid property version/visibility")
    if not isinstance(row.get("text"), str) or not isinstance(row.get("metadata"), dict):
        raise ValueError("Invalid property content")
    if row["public"] and not row["text"].strip():
        raise ValueError("Empty public property")
    return row


class PropertySource:
    def __init__(self, settings, transport=None):
        self.settings = settings
        self.transport = transport

    def _get(self, path, params=None):
        with httpx.Client(timeout=self.settings.source_timeout, transport=self.transport,
                          trust_env=False, follow_redirects=False) as client:
            response = client.get(self.settings.property_api_url.rstrip("/") + path,
                                  params=params, headers={"X-AI-Service-Token": self.settings.property_api_token})
            response.raise_for_status()
            return response.json()

    def get(self, pid):
        if self.settings.source_provider == "mock":
            return read_source(self.settings.source_path).get(pid)
        if not re.fullmatch(r"[1-9][0-9]{0,9}", str(pid)):
            raise ValueError("Invalid backend property ID")
        row = validate_record(self._get("/properties/" + str(pid)))
        if row["id"] != str(pid):
            raise ValueError("Property source ID mismatch")
        return row

    def get_many(self, ids):
        if self.settings.source_provider == "mock":
            return read_source(self.settings.source_path)
        ids = list(dict.fromkeys(ids))
        if not ids:
            return {}
        if len(ids) > 1000 or any(not re.fullmatch(r"[1-9][0-9]{0,9}", str(pid)) for pid in ids):
            raise ValueError("Invalid source lookup IDs")
        result = {}
        for offset in range(0, len(ids), 100):
            batch = ids[offset:offset + 100]
            rows = self._get("/properties/resolve", {"ids": ",".join(batch)})["records"]
            for row in rows:
                validate_record(row)
                if row["id"] not in batch or row["id"] in result:
                    raise ValueError("Invalid source lookup response")
                result[row["id"]] = row
        return result

    def page(self, after=0, limit=20):
        if self.settings.source_provider != "backend":
            raise ValueError("Backend source required")
        data = self._get("/properties", {"after": after, "limit": limit})
        rows = [validate_record(row) for row in data["records"]]
        ids = [int(row["id"]) for row in rows]
        if len(rows) > limit or ids != sorted(set(ids)) or any(pid <= after for pid in ids):
            raise ValueError("Invalid source page ordering")
        return rows
