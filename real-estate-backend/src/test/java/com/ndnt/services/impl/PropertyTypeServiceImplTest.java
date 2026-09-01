package com.ndnt.services.impl;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
import com.ndnt.converter.PropertyTypeConverter;
import com.ndnt.model.dto.PropertyTypeDTO;
import com.ndnt.model.entity.PropertyTypeEntity;
import com.ndnt.repositories.PropertyTypeRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Sort;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class PropertyTypeServiceImplTest {

    @Mock
    private PropertyTypeRepository propertyTypeRepository;

    @Mock
    private PropertyTypeConverter propertyTypeConverter;

    @InjectMocks
    private PropertyTypeServiceImpl propertyTypeService;

    @Test
    @DisplayName("getPropertyTypes - Lấy danh sách tất cả loại bất động sản")
    void getPropertyTypes_Success() {
        PropertyTypeEntity entity = new PropertyTypeEntity();
        entity.setId(1);
        PropertyTypeDTO dto = new PropertyTypeDTO();
        dto.setId(1);

        when(propertyTypeRepository.findAll(any(Sort.class))).thenReturn(List.of(entity));
        when(propertyTypeConverter.toPropertyTypeDTO(entity)).thenReturn(dto);

        List<PropertyTypeDTO> result = propertyTypeService.getPropertyTypes();

        assertNotNull(result);
        assertEquals(1, result.size());
        verify(propertyTypeRepository, times(1)).findAll(any(Sort.class));
    }

    @Test
    @DisplayName("findById - Tìm loại bất động sản theo ID")
    void findById_Success() {
        PropertyTypeEntity entity = new PropertyTypeEntity();
        entity.setId(1);
        PropertyTypeDTO dto = new PropertyTypeDTO();
        dto.setId(1);

        when(propertyTypeRepository.findById(1)).thenReturn(entity);
        when(propertyTypeConverter.toPropertyTypeDTO(entity)).thenReturn(dto);

        PropertyTypeDTO result = propertyTypeService.findById(1);

        assertNotNull(result);
        assertEquals(1, result.getId());
        verify(propertyTypeRepository, times(1)).findById(1);
    }

    @Test
    @DisplayName("createOrUpdatePropertyType - Ném DuplicateCodeException nếu mã code đã tồn tại")
    void createOrUpdatePropertyType_DuplicateCode() {
        PropertyTypeDTO dto = new PropertyTypeDTO();
        dto.setCode("APARTMENT");

        PropertyTypeEntity entity = new PropertyTypeEntity();
        entity.setCode("APARTMENT");

        when(propertyTypeConverter.toPropertyTypeEntity(dto)).thenReturn(entity);
        when(propertyTypeRepository.existsByCode("APARTMENT")).thenReturn(true);

        assertThrows(DuplicateCodeException.class, () -> {
            propertyTypeService.createOrUpdatePropertyType(dto);
        });

        verify(propertyTypeRepository, times(1)).existsByCode("APARTMENT");
    }

    @Test
    @DisplayName("deletePropertyType - Xóa cứng loại bất động sản theo ID và kiểm tra không còn trong DB")
    void deletePropertyType_Success() {
        doNothing().when(propertyTypeRepository).deleteById(1);
        when(propertyTypeRepository.findById(1)).thenReturn(null);

        propertyTypeService.deletePropertyType(1);

        verify(propertyTypeRepository, times(1)).deleteById(1);
        PropertyTypeEntity found = propertyTypeRepository.findById(1);
        assertNull(found);
    }
}
