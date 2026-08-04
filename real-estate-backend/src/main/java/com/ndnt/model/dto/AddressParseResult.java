package com.ndnt.model.dto;


public record AddressParseResult(String addressDetail,
                                 String wardName,
                                 String districtName,
                                 String cityName) {
}
