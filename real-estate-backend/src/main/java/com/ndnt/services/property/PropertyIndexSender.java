package com.ndnt.services.property;

import com.ndnt.model.entity.PropertyIndexEvent;

public interface PropertyIndexSender {
    void send(PropertyIndexEvent event) throws Exception;
}
