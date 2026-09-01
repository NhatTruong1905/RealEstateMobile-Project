package com.ndnt.controllers.api;

import com.ndnt.model.dto.InteractionTypeDTO;
import com.ndnt.services.InteractionTypeService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Collections;
import java.util.List;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
public class APIInteractionTypeControllerTest {

    private MockMvc mockMvc;

    @Mock
    private InteractionTypeService interactionTypeService;

    @InjectMocks
    private APIInteractionTypeController apiInteractionTypeController;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(apiInteractionTypeController).build();
    }

    @Test
    @DisplayName("GET /api/interaction-types - Lấy danh sách loại tương tác thành công")
    void listInteractionTypes_Success() throws Exception {
        InteractionTypeDTO typeDTO = new InteractionTypeDTO();
        typeDTO.setId(1);
        typeDTO.setName("Gọi điện");

        when(interactionTypeService.getInteractionTypes()).thenReturn(List.of(typeDTO));

        mockMvc.perform(get("/api/interaction-types"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Success"))
                .andExpect(jsonPath("$.data[0].name").value("Gọi điện"));

        verify(interactionTypeService, times(1)).getInteractionTypes();
    }

    @Test
    @DisplayName("GET /api/interaction-types - Danh sách rỗng")
    void listInteractionTypes_Empty() throws Exception {
        when(interactionTypeService.getInteractionTypes()).thenReturn(Collections.emptyList());

        mockMvc.perform(get("/api/interaction-types"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Danh sách rỗng"));

        verify(interactionTypeService, times(1)).getInteractionTypes();
    }
}
