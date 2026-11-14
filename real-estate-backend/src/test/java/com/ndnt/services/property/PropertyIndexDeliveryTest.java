package com.ndnt.services.property;

import com.ndnt.model.entity.PropertyIndexEvent;
import com.ndnt.repositories.PropertyIndexEventRepository;
import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class PropertyIndexDeliveryTest {
    @Test void failureKeepsPendingAndDoesNotPersistCredentialBearingMessage() throws Exception {
        var events=mock(PropertyIndexEventRepository.class);var sender=mock(PropertyIndexSender.class);
        var event=new PropertyIndexEvent();event.setNextAttemptAt(Instant.now().minusSeconds(1));
        when(events.locked("id")).thenReturn(Optional.of(event));
        doThrow(new IllegalStateException("synthetic private URI must not be stored")).when(sender).send(event);
        new PropertyIndexDelivery(events,sender).deliver("id");
        assertEquals("PENDING",event.getState());assertEquals(1,event.getAttempts());assertNull(event.getSentAt());
        assertEquals("IllegalStateException",event.getLastError());assertTrue(event.getNextAttemptAt().isAfter(Instant.now()));
    }
    @Test void confirmationMarksSentAndDuplicateDeliveryDoesNotPublishAgain() throws Exception {
        var events=mock(PropertyIndexEventRepository.class);var sender=mock(PropertyIndexSender.class);
        var event=new PropertyIndexEvent();event.setNextAttemptAt(Instant.now().minusSeconds(1));
        when(events.locked("id")).thenReturn(Optional.of(event));
        var delivery=new PropertyIndexDelivery(events,sender);delivery.deliver("id");delivery.deliver("id");
        assertEquals("SENT",event.getState());assertNotNull(event.getSentAt());verify(sender,times(1)).send(event);
    }
}
