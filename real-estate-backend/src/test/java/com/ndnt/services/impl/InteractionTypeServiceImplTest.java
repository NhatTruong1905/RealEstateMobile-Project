package com.ndnt.services.impl;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
import com.ndnt.converter.InteractionTypeConverter;
import com.ndnt.model.dto.InteractionTypeDTO;
import com.ndnt.model.entity.InteractionEntity;
import com.ndnt.model.entity.InteractionTypeEntity;
import com.ndnt.repositories.InteractionTypeRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class InteractionTypeServiceImplTest {

    @Mock
    private InteractionTypeRepository interactionTypeRepository;

    @Mock
    private InteractionTypeConverter interactionTypeConverter;

    @InjectMocks
    private InteractionTypeServiceImpl interactionTypeService;

    @Test
    @DisplayName("getInteractionTypes - Lấy danh sách tất cả loại tương tác")
    void getInteractionTypes_Success() {
        InteractionTypeEntity entity = new InteractionTypeEntity();
        entity.setId(1);
        entity.setCode("CALL");
        entity.setName("Gọi điện");
        entity.setInteractionEntities(new ArrayList<>());

        InteractionTypeDTO dto = new InteractionTypeDTO();
        dto.setId(1);
        dto.setCode("CALL");
        dto.setName("Gọi điện");

        when(interactionTypeRepository.findAll()).thenReturn(List.of(entity));
        when(interactionTypeConverter.toInteractionTypeDTO(entity)).thenReturn(dto);

        List<InteractionTypeDTO> result = interactionTypeService.getInteractionTypes();

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("CALL", result.get(0).getCode());
        verify(interactionTypeRepository, times(1)).findAll();
    }

    @Test
    @DisplayName("findById - Tìm thấy loại tương tác theo ID")
    void findById_Success() {
        InteractionTypeEntity entity = new InteractionTypeEntity();
        entity.setId(1);
        InteractionTypeDTO dto = new InteractionTypeDTO();
        dto.setId(1);

        when(interactionTypeRepository.findById(1)).thenReturn(Optional.of(entity));
        when(interactionTypeConverter.toInteractionTypeDTO(entity)).thenReturn(dto);

        InteractionTypeDTO result = interactionTypeService.findById(1);

        assertNotNull(result);
        assertEquals(1, result.getId());
        verify(interactionTypeRepository, times(1)).findById(1);
    }

    @Test
    @DisplayName("createOrUpdateInteractionType - Ném DuplicateCodeException nếu mã code đã tồn tại")
    void createOrUpdateInteractionType_DuplicateCode() {
        InteractionTypeDTO dto = new InteractionTypeDTO();
        dto.setCode("CALL");

        InteractionTypeEntity entity = new InteractionTypeEntity();
        entity.setCode("CALL");

        when(interactionTypeConverter.toInteractionTypeEntity(dto)).thenReturn(entity);
        when(interactionTypeRepository.existsByCode("CALL")).thenReturn(true);

        assertThrows(DuplicateCodeException.class, () -> {
            interactionTypeService.createOrUpdateInteractionType(dto);
        });

        verify(interactionTypeRepository, times(1)).existsByCode("CALL");
    }

    @Test
    @DisplayName("deleteInteractionType - Xóa cứng loại tương tác theo ID và kiểm tra không còn trong DB")
    void deleteInteractionType_Success() {
        doNothing().when(interactionTypeRepository).deleteById(1);
        when(interactionTypeRepository.findById(1)).thenReturn(Optional.empty());

        interactionTypeService.deleteInteractionType(1);

        verify(interactionTypeRepository, times(1)).deleteById(1);
        Optional<InteractionTypeEntity> found = interactionTypeRepository.findById(1);
        assertTrue(found.isEmpty());
    }
}
