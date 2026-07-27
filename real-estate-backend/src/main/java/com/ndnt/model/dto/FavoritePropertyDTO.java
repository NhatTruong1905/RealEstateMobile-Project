package com.ndnt.model.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class FavoritePropertyDTO extends BaseDTO {
    private Integer propertyId;
    private Integer userId;
    private List<Integer> propertyIds;
}
