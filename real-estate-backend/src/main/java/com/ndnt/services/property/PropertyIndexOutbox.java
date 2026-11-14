package com.ndnt.services.property;

import com.ndnt.model.entity.*;
import com.ndnt.model.enums.StatusProperty;
import com.ndnt.repositories.PropertyIndexEventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
import java.util.UUID;

@Service @RequiredArgsConstructor
public class PropertyIndexOutbox {
    private final PropertyIndexEventRepository events;

    @Transactional(propagation=Propagation.MANDATORY)
    public void enqueue(PropertyEntity property, boolean approval) {
        boolean visible = StatusProperty.PUBLISHED.getStatus().equals(property.getStatus());
        PropertyIndexEvent event = new PropertyIndexEvent();
        event.setId(UUID.randomUUID().toString());
        event.setPropertyId(property.getId());
        event.setAggregateVersion(property.getIndexVersion());
        event.setOperation(visible ? "upsert" : "delete");
        event.setRoutingKey(visible ? (approval ? "property.approved" : "property.updated") :
                (StatusProperty.DELETED.getStatus().equals(property.getStatus()) ? "property.deleted" : "property.unpublished"));
        events.save(event);
    }
}
