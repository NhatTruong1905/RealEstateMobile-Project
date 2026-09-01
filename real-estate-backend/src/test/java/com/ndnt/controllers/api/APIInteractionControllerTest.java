package com.ndnt.controllers.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ndnt.model.dto.InteractionDTO;
import com.ndnt.model.dto.UserDTO;
import com.ndnt.services.InteractionService;
import com.ndnt.services.UserService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.security.Principal;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
public class APIInteractionControllerTest {

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;

    @Mock
    private InteractionService interactionService;

    @Mock
    private UserService userService;

    @InjectMocks
    private APIInteractionController apiInteractionController;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(apiInteractionController).build();
        objectMapper = new ObjectMapper();
    }

    @Test
    @DisplayName("POST /api/secure/interactions - Thêm mới hoặc cập nhật tương tác thành công")
    void addInteraction_Success() throws Exception {
        InteractionDTO interactionDTO = new InteractionDTO();
        interactionDTO.setPropertyId(1);
        interactionDTO.setSenderId(2);

        doNothing().when(interactionService).createOrUpdateInteraction(any(InteractionDTO.class));

        mockMvc.perform(post("/api/secure/interactions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(interactionDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Success"));

        verify(interactionService, times(1)).createOrUpdateInteraction(any(InteractionDTO.class));
    }

    @Test
    @DisplayName("GET /api/secure/interactions/property/{propertyId} - Lấy tương tác của người gửi thành công")
    void getInteractionOfSender_Success() throws Exception {
        Principal principal = () -> "senderUser";
        UserDTO userDTO = new UserDTO();
        userDTO.setId(1);
        userDTO.setUsername("senderUser");

        InteractionDTO interactionDTO = new InteractionDTO();
        interactionDTO.setId(10);
        interactionDTO.setPropertyId(5);

        when(userService.findByUsername("senderUser")).thenReturn(userDTO);
        when(interactionService.getInteractionOfSender(5, 1)).thenReturn(List.of(interactionDTO));

        mockMvc.perform(get("/api/secure/interactions/property/{propertyId}", 5)
                        .principal(principal))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Success"))
                .andExpect(jsonPath("$.data[0].id").value(10));

        verify(userService, times(1)).findByUsername("senderUser");
        verify(interactionService, times(1)).getInteractionOfSender(5, 1);
    }

    @Test
    @DisplayName("GET /api/secure/interactions-receiver - Lấy tương tác của người nhận thành công")
    void getInteractionsOfReceiver_Success() throws Exception {
        Principal principal = () -> "receiverUser";
        UserDTO userDTO = new UserDTO();
        userDTO.setId(2);
        userDTO.setUsername("receiverUser");

        InteractionDTO interactionDTO = new InteractionDTO();
        interactionDTO.setId(20);

        when(userService.findByUsername("receiverUser")).thenReturn(userDTO);
        when(interactionService.getInteractionsOfReiver(2)).thenReturn(List.of(interactionDTO));

        mockMvc.perform(get("/api/secure/interactions-receiver")
                        .principal(principal))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Success"))
                .andExpect(jsonPath("$.data[0].id").value(20));

        verify(userService, times(1)).findByUsername("receiverUser");
        verify(interactionService, times(1)).getInteractionsOfReiver(2);
    }

    @Test
    @DisplayName("POST /api/secure/interactions/completed - Xác nhận hoàn thành xem nhà")
    void viewingCompleted_Success() throws Exception {
        InteractionDTO interactionDTO = new InteractionDTO();
        interactionDTO.setId(10);
        List<InteractionDTO> list = List.of(interactionDTO);

        doNothing().when(interactionService).viewingCompleted(anyList());

        mockMvc.perform(post("/api/secure/interactions/completed")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(list)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Success"));

        verify(interactionService, times(1)).viewingCompleted(anyList());
    }
}
