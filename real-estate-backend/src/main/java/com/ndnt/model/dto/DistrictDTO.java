package com.ndnt.model.dto;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Setter
@Getter
public class DistrictDTO extends BaseDTO {
    @NotBlank(message = "Mã code Quận/Huyện không được để trống!")
    private String code;
    @NotBlank(message = "Tên Quận/Huyện không được để trống!")
    private String name;
    @JsonIgnore
    private List<Integer> wardIds = new ArrayList<>();
}
