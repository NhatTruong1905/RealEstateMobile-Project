package com.ndnt.model.dto;

import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Setter
@Getter
public class PropertyDTO extends BaseDTO {
    private Integer userId;
    private Integer typeId;
    private Integer categoryId;
    private String title;
    private String description;
    private String address;
    private String city;
    private Integer wardId;
    private String addressDetail;
    private BigDecimal price;
    private BigDecimal area;
    private Integer floorCount;
    private Integer bedroomCount;
    private Integer bathroomCount;
    private String direction;
    private String legal;
    private String status;
    private List<Integer> assignmentIds = new ArrayList<>();
}
