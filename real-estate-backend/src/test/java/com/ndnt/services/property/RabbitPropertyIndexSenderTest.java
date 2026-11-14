package com.ndnt.services.property;

import com.ndnt.model.entity.PropertyIndexEvent;
import com.rabbitmq.client.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.test.util.ReflectionTestUtils;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;

class RabbitPropertyIndexSenderTest {
    @Test @EnabledIfEnvironmentVariable(named="AI_TEST_RABBITMQ_URL",matches=".+")
    void sendsConfirmedPersistentEventToRealBroker() throws Exception {
        String uri=System.getenv("AI_TEST_RABBITMQ_URL");
        RabbitPropertyIndexSender sender=new RabbitPropertyIndexSender();
        ReflectionTestUtils.setField(sender,"uri",uri);
        ReflectionTestUtils.setField(sender,"queueType","quorum");
        ConnectionFactory factory=new ConnectionFactory(); factory.setUri(uri);
        try(Connection connection=factory.newConnection();Channel channel=connection.createChannel()) {
            channel.exchangeDeclare("property.events.v1","topic",true);
            String queue=channel.queueDeclare().getQueue();
            channel.queueBind(queue,"property.events.v1","property.approved");
            var e=new PropertyIndexEvent();e.setId(UUID.randomUUID().toString());e.setPropertyId(123);
            e.setAggregateVersion(4);e.setOperation("upsert");e.setRoutingKey("property.approved");
            sender.send(e);
            GetResponse message=channel.basicGet(queue,true);
            assertNotNull(message);
            String body=new String(message.getBody(),StandardCharsets.UTF_8);
            assertTrue(body.contains(e.getId())); assertTrue(body.contains("\"aggregateVersion\":4"));
            assertEquals(2,message.getProps().getDeliveryMode());
            assertEquals(e.getId(),message.getProps().getMessageId());
        }
    }
}
