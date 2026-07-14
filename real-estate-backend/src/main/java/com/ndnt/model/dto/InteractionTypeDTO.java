package com.ndnt.model.dto;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Setter
@Getter
public class InteractionTypeDTO extends BaseDTO {
    @NotBlank(message = "Mã tương tác không được để trống!")
    private String code;
    @NotBlank(message = "Tên tương tác không được để trống!")
    private String name;
    @JsonIgnore
    private List<Integer> interactionIds = new ArrayList<>();
}
