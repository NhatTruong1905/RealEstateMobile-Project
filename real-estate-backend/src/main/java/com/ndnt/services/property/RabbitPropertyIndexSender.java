package com.ndnt.services.property;

import com.ndnt.model.entity.PropertyIndexEvent;
import com.rabbitmq.client.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

@Component
public class RabbitPropertyIndexSender implements PropertyIndexSender {
    @Value("${property.index.rabbitmq-url:}") private String uri;
    @Value("${property.index.queue-type:quorum}") private String queueType;

    @Override public void send(PropertyIndexEvent e) throws Exception {
        if (uri.isBlank() || !(queueType.equals("quorum") || queueType.equals("classic")))
            throw new IllegalStateException("Configure property indexing broker");
        ConnectionFactory factory = new ConnectionFactory();
        factory.setUri(uri);
        if (uri.startsWith("amqps://")) {
            factory.useSslProtocol(javax.net.ssl.SSLContext.getDefault());
            factory.enableHostnameVerification();
        }
        factory.setConnectionTimeout(10000);
        factory.setHandshakeTimeout(10000);
        factory.setAutomaticRecoveryEnabled(false);
        try (Connection connection = factory.newConnection("property-index-outbox");
             Channel channel = connection.createChannel()) {
            channel.exchangeDeclare("property.events.v1", "topic", true);
            Map<String,Object> args = new java.util.HashMap<>();
            args.put("x-queue-type", queueType);
            if (queueType.equals("quorum")) args.put("x-delivery-limit", -1);
            channel.queueDeclare("ai.property.index.v1", true, false, false, args);
            channel.queueBind("ai.property.index.v1", "property.events.v1", "property.*");
            AtomicBoolean returned = new AtomicBoolean(false);
            channel.addReturnListener(message -> returned.set(true));
            channel.confirmSelect();
            String body = "{\"schemaVersion\":1,\"eventId\":\""+e.getId()+"\",\"propertyId\":\""+e.getPropertyId()+
                    "\",\"aggregateVersion\":"+e.getAggregateVersion()+",\"operation\":\""+e.getOperation()+
                    "\",\"occurredAt\":\""+e.getCreatedAt()+"\"}";
            var props = new AMQP.BasicProperties.Builder().contentType("application/json")
                    .deliveryMode(2).messageId(e.getId()).build();
            channel.basicPublish("property.events.v1", e.getRoutingKey(), true, props, body.getBytes(StandardCharsets.UTF_8));
            channel.waitForConfirmsOrDie(10000);
            if (returned.get()) throw new IllegalStateException("Unroutable property event");
        }
    }
}
