package com.ndnt.model.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public class WardDTO extends BaseDTO {
    @NotBlank(message = "Mã code Phường/Xã không được để trống!")
    private String code;
    @NotBlank(message = "Tên Phường/Xã không được để trống!")
    private String name;
    private Integer districtId;
    private String districtName;
    private String districtCode;
}
