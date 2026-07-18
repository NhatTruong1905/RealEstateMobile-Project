package com.ndnt.model.dto.request;

import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public class InteractionRequestDTO {
    private String username;
    private String title;
    private String interactionTypeId;
    private Integer staffId;
}
