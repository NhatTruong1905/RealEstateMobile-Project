package com.ndnt.controllers.api;

import com.ndnt.model.dto.ChatMessageDTO;
import com.ndnt.services.InteractionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RestController;

@Controller
public class APIChatController {
    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    /* /app/chat */
    @MessageMapping("/chat")
    public void processMessage(@Payload ChatMessageDTO messageDTO) {
        if (messageDTO.getPropertyId() != null) {
            this.messagingTemplate.convertAndSend(
                    "/topic/chat/" + messageDTO.getPropertyId(),
                    messageDTO
            );
        }

        if (messageDTO.getReceiverId() != null) {
            this.messagingTemplate.convertAndSend(
                    "/topic/user/" + messageDTO.getReceiverId(),
                    messageDTO
            );
            this.messagingTemplate.convertAndSendToUser(
                    String.valueOf(messageDTO.getReceiverId()),
                    "/queue/messages",
                    messageDTO
            );
        }
    }

    /* /app/chat/accept */
    @MessageMapping("/chat/accept")
    public void processAcceptance(@Payload ChatMessageDTO messageDTO) {
        if (messageDTO.getPropertyId() != null) {
            this.messagingTemplate.convertAndSend(
                    "/topic/chat/" + messageDTO.getPropertyId(),
                    messageDTO
            );
        }
        if (messageDTO.getReceiverId() != null) {
            this.messagingTemplate.convertAndSend(
                    "/topic/user/" + messageDTO.getReceiverId(),
                    messageDTO
            );
        }
    }
}
