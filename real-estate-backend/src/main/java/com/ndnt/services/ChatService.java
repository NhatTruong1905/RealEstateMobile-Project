package com.ndnt.services;

import com.ndnt.model.dto.AddressParseResult;

public interface ChatService {
    AddressParseResult parseAddress(String rawAddress);
}
