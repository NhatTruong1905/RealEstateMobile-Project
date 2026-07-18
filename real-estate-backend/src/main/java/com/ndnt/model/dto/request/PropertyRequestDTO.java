package com.ndnt.model.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;

@Setter
@Getter
public class PropertyRequestDTO {
    private String title;
    private BigDecimal toPrice;
    private BigDecimal fromPrice;
    private BigDecimal area;
    private String address;
    private Integer districtId;
    private Integer wardId;
    private Integer floorCount;
    private Integer bedroomCount;
    private Integer bathroomCount;
    private String direction;
    private String legal;
    private Integer staffId;
}
