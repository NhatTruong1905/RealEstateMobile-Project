import os
import ssl
from dataclasses import dataclass, field
import pika


EXCHANGE = "property.events.v1"
QUEUE = "ai.property.index.v1"
RETRY = "ai.property.index.retry.v1"
DLQ = "ai.property.index.dlq.v1"


@dataclass(frozen=True)
class BrokerSettings:
    url: str = field(repr=False)
    queue_type: str = "quorum"
    retry_ms: int = 30000
    max_retries: int = 5

    @classmethod
    def from_env(cls):
        result = cls(os.getenv("RABBITMQ_URL", ""), os.getenv("RABBITMQ_QUEUE_TYPE", "quorum"),
                     int(os.getenv("RABBITMQ_RETRY_DELAY_MS", "30000")), int(os.getenv("RABBITMQ_MAX_RETRIES", "5")))
        if not result.url.startswith(("amqp://", "amqps://")) or result.queue_type not in {"quorum", "classic"}:
            raise ValueError("Set RABBITMQ_URL and valid RABBITMQ_QUEUE_TYPE")
        if not 1000 <= result.retry_ms <= 3600000 or not 0 <= result.max_retries <= 20:
            raise ValueError("Invalid retry policy")
        return result

    def parameters(self):
        params = pika.URLParameters(self.url)
        params.heartbeat = 0
        params.blocked_connection_timeout = 30
        params.socket_timeout = 10
        params.stack_timeout = 20
        params.connection_attempts = 1
        if self.url.startswith("amqps://"):
            params.ssl_options = pika.SSLOptions(ssl.create_default_context(), params.host)
        return params


def declare_topology(channel, settings):
    channel.exchange_declare(exchange=EXCHANGE, exchange_type="topic", durable=True)
    channel.exchange_declare(exchange=RETRY, exchange_type="direct", durable=True)
    channel.exchange_declare(exchange=DLQ, exchange_type="direct", durable=True)
    args = {"x-queue-type": settings.queue_type}
    main_args = {**args, **({"x-delivery-limit": -1} if settings.queue_type == "quorum" else {})}
    channel.queue_declare(queue=QUEUE, durable=True, arguments=main_args)
    channel.queue_bind(queue=QUEUE, exchange=EXCHANGE, routing_key="property.*")
    channel.queue_bind(queue=QUEUE, exchange=RETRY, routing_key="ready")
    retry_args = {**args, "x-message-ttl": settings.retry_ms,
                  "x-dead-letter-exchange": RETRY, "x-dead-letter-routing-key": "ready"}
    if settings.queue_type == "quorum":
        retry_args.update({"x-dead-letter-strategy": "at-least-once", "x-overflow": "reject-publish"})
    channel.queue_declare(queue=RETRY, durable=True, arguments=retry_args)
    channel.queue_bind(queue=RETRY, exchange=RETRY, routing_key="retry")
    channel.queue_declare(queue=DLQ, durable=True, arguments=args)
    channel.queue_bind(queue=DLQ, exchange=DLQ, routing_key="failed")
