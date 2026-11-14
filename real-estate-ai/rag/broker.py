import argparse
import json
from dotenv import load_dotenv
import pika
from rag.messaging import BrokerSettings, EXCHANGE, QUEUE, RETRY, DLQ, declare_topology
from rag.worker import parse_event


def main():
    load_dotenv()
    parser=argparse.ArgumentParser()
    parser.add_argument("command",choices=["check","redrive"])
    parser.add_argument("--limit",type=int,default=10)
    args=parser.parse_args()
    if not 1<=args.limit<=100: parser.error("limit must be 1..100")
    broker=BrokerSettings.from_env()
    with pika.BlockingConnection(broker.parameters()) as connection:
        channel=connection.channel()
        declare_topology(channel,broker)
        if args.command=="check":
            print(json.dumps({"status":"ok","ready":{
                name:channel.queue_declare(queue=name,passive=True).method.message_count
                for name in [QUEUE,RETRY,DLQ]}}))
            return
        channel.confirm_delivery()
        moved=0
        for _ in range(args.limit):
            method,props,body=channel.basic_get(DLQ,auto_ack=False)
            if not method: break
            try:
                event=parse_event(body)
            except ValueError:
                channel.basic_nack(method.delivery_tag,requeue=True)
                print(json.dumps({"status":"needs_event_repair","redriven":moved}))
                return 1
            headers=dict(props.headers or {})
            headers["x-index-retries"]=0
            headers.pop("x-index-error",None)
            routing="property.deleted" if event["operation"]=="delete" else "property.updated"
            channel.basic_publish(EXCHANGE,routing,body,mandatory=True,
                properties=pika.BasicProperties(content_type="application/json",delivery_mode=2,
                                               message_id=props.message_id,headers=headers))
            channel.basic_ack(method.delivery_tag)
            moved+=1
        print(json.dumps({"status":"ok","redriven":moved}))


if __name__=="__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(json.dumps({"status":"failed","reason":type(error).__name__}))
        raise SystemExit(1)
