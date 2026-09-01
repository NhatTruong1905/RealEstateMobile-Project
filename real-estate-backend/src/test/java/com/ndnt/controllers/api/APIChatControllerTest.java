package com.ndnt.controllers.api;

import com.ndnt.model.dto.ChatMessageDTO;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class APIChatControllerTest {

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    @InjectMocks
    private APIChatController apiChatController;

    @Test
    @DisplayName("processMessage - Gửi tin nhắn qua WebSocket tới topic chat và receiver queue")
    void processMessage_Success() {
        ChatMessageDTO messageDTO = new ChatMessageDTO();
        messageDTO.setPropertyId(1);
        messageDTO.setReceiverId(2);
        messageDTO.setMessage("Xin chào!");

        apiChatController.processMessage(messageDTO);

        verify(messagingTemplate, times(1)).convertAndSend("/topic/chat/1", messageDTO);
        verify(messagingTemplate, times(1)).convertAndSend("/topic/user/2", messageDTO);
        verify(messagingTemplate, times(1)).convertAndSendToUser("2", "/queue/messages", messageDTO);
    }

    @Test
    @DisplayName("processAcceptance - Xử lý chấp nhận chat gửi tới topic chat và user")
    void processAcceptance_Success() {
        ChatMessageDTO messageDTO = new ChatMessageDTO();
        messageDTO.setPropertyId(1);
        messageDTO.setReceiverId(2);

        apiChatController.processAcceptance(messageDTO);

        verify(messagingTemplate, times(1)).convertAndSend("/topic/chat/1", messageDTO);
        verify(messagingTemplate, times(1)).convertAndSend("/topic/user/2", messageDTO);
    }
}
