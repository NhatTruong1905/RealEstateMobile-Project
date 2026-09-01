package com.ndnt.services;

import com.ndnt.model.dto.AddressParseResult;

public interface AddressParseService {
    AddressParseResult parseAddress(String rawAddress);
}
