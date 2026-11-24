import os
import re
import ssl
from contextlib import closing, contextmanager
from pathlib import Path
from urllib.parse import unquote, urlsplit


def connect_postgres(dsn):
    import pg8000.dbapi

    url = urlsplit(dsn)
    if url.scheme not in {"postgresql", "postgres"} or not url.hostname or not url.username:
        raise ValueError("Invalid QDRANT_STATE_DATABASE_URL")
    ca_file = os.getenv("QDRANT_STATE_DATABASE_CA_FILE")
    if ca_file and not Path(ca_file).is_absolute():
        ca_file = str(Path(__file__).resolve().parents[1] / ca_file)
    return pg8000.dbapi.connect(
        host=url.hostname,
        port=url.port or 5432,
        database=unquote(url.path.lstrip("/")) or "postgres",
        user=unquote(url.username),
        password=unquote(url.password or ""),
        ssl_context=ssl.create_default_context(cafile=ca_file or None),
        timeout=30,
    )


class IndexState:
    def __init__(self, settings):
        self.settings = settings

    def initialize(self):
        with self.connect() as db:
            self.execute(db, "SELECT pg_advisory_xact_lock(154396231, 0)")
            self.execute(db, "CREATE SCHEMA IF NOT EXISTS chatbot_index")
            self.execute(db, "CREATE TABLE IF NOT EXISTS manifest "
                         "(id INTEGER PRIMARY KEY CHECK(id=1), value TEXT NOT NULL)")
            self.execute(db, "CREATE TABLE IF NOT EXISTS parents "
                         "(id TEXT PRIMARY KEY, version BIGINT NOT NULL, hash TEXT NOT NULL, "
                         "document TEXT NOT NULL, points TEXT NOT NULL, public INTEGER NOT NULL)")

    @contextmanager
    def connect(self):
        with closing(connect_postgres(self.settings.state_database_url)) as connection:
            try:
                self.execute(connection, "SET LOCAL search_path TO chatbot_index")
                yield connection
                connection.commit()
            except BaseException:
                connection.rollback()
                raise

    def execute(self, connection, sql, parameters=()):
        cursor = connection.cursor()
        cursor.execute(sql.replace("?", "%s"), parameters)
        return cursor

    def lock_property(self, connection, property_id):
        self.execute(connection, "SELECT pg_advisory_xact_lock(154396231, CAST(? AS integer))",
                     (property_id,))

    def search_text(self, text, limit):
        terms = list(dict.fromkeys(re.findall(r"[^\W_]+", text.lower())))[:24]
        if not terms:
            return []
        query = " | ".join(terms)
        with self.connect() as db:
            return [row[0] for row in self.execute(db, """
                SELECT id FROM parents
                CROSS JOIN to_tsquery('simple', ?) AS query
                WHERE public = 1 AND to_tsvector('simple', document::jsonb ->> 'text') @@ query
                ORDER BY ts_rank(to_tsvector('simple', document::jsonb ->> 'text'), query) DESC, id
                LIMIT ?
            """, (query, limit)).fetchall()]
