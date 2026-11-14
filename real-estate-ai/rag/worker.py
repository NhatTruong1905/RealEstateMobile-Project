import argparse
import json
import logging
import time
import uuid
from datetime import datetime
from pathlib import Path
import httpx
import pika
from dotenv import load_dotenv
from rag.config import Settings
from rag.embedding_contract import embedding_contract
from rag.messaging import BrokerSettings, EXCHANGE, QUEUE, RETRY, DLQ, declare_topology
from rag.providers import create_embedding
from rag.qdrant_store import QdrantParentStore

log = logging.getLogger(__name__)


class PermanentEventError(ValueError):
    pass


def parse_event(body):
    try:
        if len(body) > 65536:
            raise ValueError()
        event = json.loads(body)
        if not isinstance(event["eventId"], str):
            raise ValueError()
        uuid.UUID(event["eventId"])
        occurred = datetime.fromisoformat(event["occurredAt"].replace("Z", "+00:00"))
        if occurred.tzinfo is None:
            raise ValueError()
        if type(event["schemaVersion"]) is not int or event["schemaVersion"] != 1 or event["operation"] not in {"upsert", "delete"}:
            raise ValueError()
        if type(event["aggregateVersion"]) is not int or event["aggregateVersion"] < 1:
            raise ValueError()
        pid = str(event["propertyId"])
        if not pid.isascii() or not pid.isdecimal() or not 0 < int(pid) <= 2147483647:
            raise ValueError()
        event["propertyId"] = pid
        return event
    except (ValueError, TypeError, KeyError, OverflowError, AttributeError):
        raise PermanentEventError("Invalid property event") from None


def process_event(store, event):
    row = store.source.get(event["propertyId"])
    if row["version"] < event["aggregateVersion"]:
        raise RuntimeError("Source behind event version")
    return store.apply_property(row)


def delivery_handler(store, settings):
    def callback(channel, method, properties, body):
        try:
            event = parse_event(body)
            action = process_event(store, event)
            channel.basic_ack(method.delivery_tag)
            log.info("index status=ok action=%s", action)
        except Exception as exc:
            headers = dict(properties.headers or {})
            attempts = headers.get("x-index-retries", 0)
            attempts = attempts if type(attempts) is int and attempts >= 0 else settings.max_retries
            permanent = isinstance(exc, PermanentEventError)
            if isinstance(exc, httpx.HTTPStatusError):
                permanent = exc.response.status_code in {400, 404, 422}
            failed = permanent or attempts >= settings.max_retries
            headers.update({"x-index-retries": attempts + 1, "x-index-error": type(exc).__name__})
            channel.basic_publish(exchange=DLQ if failed else RETRY,
                                  routing_key="failed" if failed else "retry", body=body, mandatory=True,
                                  properties=pika.BasicProperties(content_type="application/json", delivery_mode=2,
                                                                  message_id=properties.message_id, headers=headers))
            channel.basic_ack(method.delivery_tag)
            log.warning("index status=%s reason=%s", "dead_letter" if failed else "retry", type(exc).__name__)
    return callback


def main():
    load_dotenv()
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default="vector_database/embedding-smoke.json")
    parser.add_argument("--once", action="store_true", help="Process at most one message for a smoke test")
    args = parser.parse_args()
    settings = Settings.from_env()
    broker = BrokerSettings.from_env()
    if settings.source_provider != "backend":
        raise ValueError("Worker requires INDEX_SOURCE_PROVIDER=backend")
    store = QdrantParentStore(settings, create_embedding(settings))
    connection = None
    try:
        contract = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
        if contract != embedding_contract(settings, contract["dimension"]):
            raise ValueError("Smoke manifest mismatch")
        store.validate(contract, create=True)
        while True:
            try:
                connection = pika.BlockingConnection(broker.parameters())
                channel = connection.channel()
                declare_topology(channel, broker)
                channel.confirm_delivery()
                channel.basic_qos(prefetch_count=1)
                handler = delivery_handler(store, broker)
                if args.once:
                    method, props, body = channel.basic_get(QUEUE, auto_ack=False)
                    if method:
                        handler(channel, method, props, body)
                    return
                channel.basic_consume(QUEUE, on_message_callback=handler, auto_ack=False)
                channel.start_consuming()
            except (pika.exceptions.AMQPError, OSError) as exc:
                log.warning("broker status=reconnecting reason=%s", type(exc).__name__)
                if args.once:
                    raise
                time.sleep(5)
            finally:
                if connection and connection.is_open:
                    connection.close()
    finally:
        store.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    try:
        main()
    except KeyboardInterrupt:
        pass
    except Exception as exc:
        log.error("worker status=failed reason=%s", type(exc).__name__)
        raise SystemExit(1)
