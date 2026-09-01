package com.ndnt.services.impl;

import com.ndnt.converter.InteractionConverter;
import com.ndnt.model.dto.InteractionDTO;
import com.ndnt.model.entity.InteractionEntity;
import com.ndnt.model.entity.InteractionTypeEntity;
import com.ndnt.repositories.InteractionRepository;
import com.ndnt.repositories.InteractionTypeRepository;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.repositories.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class InteractionServiceImplTest {

    @Mock
    private InteractionRepository interactionRepository;

    @Mock
    private InteractionConverter interactionConverter;

    @Mock
    private PropertyRepository propertyRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private InteractionTypeRepository interactionTypeRepository;

    @InjectMocks
    private InteractionServiceImpl interactionService;

    @Test
    @DisplayName("getInteractionOfSender - Lấy tương tác của người gửi")
    void getInteractionOfSender_Success() {
        InteractionEntity entity = new InteractionEntity();
        entity.setId(1);
        InteractionDTO dto = new InteractionDTO();
        dto.setId(1);

        when(interactionRepository.findByProperty_IdAndSender_Id(10, 5)).thenReturn(List.of(entity));
        when(interactionConverter.toInteractionDTO(entity)).thenReturn(dto);

        List<InteractionDTO> result = interactionService.getInteractionOfSender(10, 5);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(1, result.get(0).getId());
        verify(interactionRepository, times(1)).findByProperty_IdAndSender_Id(10, 5);
    }

    @Test
    @DisplayName("getInteractionsOfReiver - Lấy tương tác của người nhận")
    void getInteractionsOfReceiver_Success() {
        InteractionEntity entity = new InteractionEntity();
        entity.setId(2);
        InteractionDTO dto = new InteractionDTO();
        dto.setId(2);

        when(interactionRepository.findByReceiver_IdOrderByIdDesc(6)).thenReturn(List.of(entity));
        when(interactionConverter.toInteractionDTO(entity)).thenReturn(dto);

        List<InteractionDTO> result = interactionService.getInteractionsOfReiver(6);

        assertNotNull(result);
        assertEquals(1, result.size());
        verify(interactionRepository, times(1)).findByReceiver_IdOrderByIdDesc(6);
    }

    @Test
    @DisplayName("viewingCompleted - Đánh dấu xem nhà hoàn thành")
    void viewingCompleted_Success() {
        InteractionDTO dto = new InteractionDTO();
        dto.setPropertyId(10);
        dto.setSenderId(1);
        dto.setReceiverId(2);

        InteractionTypeEntity type1 = new InteractionTypeEntity();
        type1.setId(1);
        type1.setCode("MESSAGE");

        InteractionTypeEntity type2 = new InteractionTypeEntity();
        type2.setId(2);
        type2.setCode("VIEWING");

        when(interactionTypeRepository.findByCodeIn(Arrays.asList("MESSAGE", "VIEWING"))).thenReturn(List.of(type1, type2));

        interactionService.viewingCompleted(List.of(dto));

        verify(interactionRepository, times(1)).updateStatusToZeroForSpecificTypes(10, 1, 2, List.of(1, 2));
    }

    @Test
    @DisplayName("deleteInteraction - Xóa mềm tương tác (status = 0)")
    void deleteInteraction_Success() {
        InteractionEntity interactionEntity = new InteractionEntity();
        interactionEntity.setId(1);
        interactionEntity.setStatus(1);

        when(interactionRepository.findById(1)).thenReturn(Optional.of(interactionEntity));
        when(interactionRepository.save(interactionEntity)).thenReturn(interactionEntity);

        interactionService.deleteInteraction(1);

        assertEquals(0, interactionEntity.getStatus());
        verify(interactionRepository, times(1)).findById(1);
        verify(interactionRepository, times(1)).save(interactionEntity);
    }
}
