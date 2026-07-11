package com.ndnt.model.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public class PropertyTypeDTO extends BaseDTO {
    @NotBlank(message = "Mã code loại không được để trống!")
    private String code;
    @NotBlank(message = "Tên loại không được để trống!")
    private String name;
}
