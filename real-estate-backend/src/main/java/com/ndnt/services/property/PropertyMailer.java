package com.ndnt.services.property;
import com.ndnt.model.entity.PropertyMailEvent;
public interface PropertyMailer { void send(PropertyMailEvent event) throws Exception; }
