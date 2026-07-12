package com.ndnt.model.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public class PropertyCategoryDTO extends BaseDTO {
    @NotBlank(message = "Mã code phân khúc không được để trống!")
    private String code;
    @NotBlank(message = "Tên phân khúc không được để trống!")
    private String name;
}
