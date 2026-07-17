package com.ndnt.model.dto;

import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public class InteractionDTO extends BaseDTO {
    private Integer propertyId;
    private Integer senderId;
    private Integer receiverId;
    private Integer interactionTypeId;
    private String propertyTitle;
    private String senderUsername;
    private String receiverUsername;
    private String interactionTypeName;
    private String message;
    private Integer status = 1;
}
