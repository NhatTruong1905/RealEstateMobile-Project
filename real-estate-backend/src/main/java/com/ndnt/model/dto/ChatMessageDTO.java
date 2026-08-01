package com.ndnt.model.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ChatMessageDTO extends BaseDTO {
    private Integer senderId;
    private Integer receiverId;
    private Integer propertyId;
    private String message;
    private String senderName;
    private String timestamp;
}
