package com.ndnt.model.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Setter
@Getter
public class AssignmentDTO extends BaseDTO {
    private Integer propertyId;
    private List<Integer> staffIds;
}
