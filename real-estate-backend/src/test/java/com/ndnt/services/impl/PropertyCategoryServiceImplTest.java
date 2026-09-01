package com.ndnt.services.impl;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
import com.ndnt.converter.PropertyCategoryConverter;
import com.ndnt.model.dto.PropertyCategoryDTO;
import com.ndnt.model.entity.PropertyCategoryEntity;
import com.ndnt.repositories.PropertyCategoryRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Sort;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class PropertyCategoryServiceImplTest {

    @Mock
    private PropertyCategoryRepository propertyCategoryRepository;

    @Mock
    private PropertyCategoryConverter propertyCategoryConverter;

    @InjectMocks
    private PropertyCategoryServiceImpl propertyCategoryService;

    @Test
    @DisplayName("getPropertyCategories - Lấy danh sách tất cả phân khúc bất động sản")
    void getPropertyCategories_Success() {
        PropertyCategoryEntity entity = new PropertyCategoryEntity();
        entity.setId(1);
        PropertyCategoryDTO dto = new PropertyCategoryDTO();
        dto.setId(1);

        when(propertyCategoryRepository.findAll(any(Sort.class))).thenReturn(List.of(entity));
        when(propertyCategoryConverter.toPropertyCategoryDTO(entity)).thenReturn(dto);

        List<PropertyCategoryDTO> result = propertyCategoryService.getPropertyCategories();

        assertNotNull(result);
        assertEquals(1, result.size());
        verify(propertyCategoryRepository, times(1)).findAll(any(Sort.class));
    }

    @Test
    @DisplayName("findById - Tìm phân khúc theo ID")
    void findById_Success() {
        PropertyCategoryEntity entity = new PropertyCategoryEntity();
        entity.setId(1);
        PropertyCategoryDTO dto = new PropertyCategoryDTO();
        dto.setId(1);

        when(propertyCategoryRepository.findById(1)).thenReturn(entity);
        when(propertyCategoryConverter.toPropertyCategoryDTO(entity)).thenReturn(dto);

        PropertyCategoryDTO result = propertyCategoryService.findById(1);

        assertNotNull(result);
        assertEquals(1, result.getId());
        verify(propertyCategoryRepository, times(1)).findById(1);
    }

    @Test
    @DisplayName("createOrUpdatePropertyCategory - Ném DuplicateCodeException nếu mã code đã tồn tại")
    void createOrUpdatePropertyCategory_DuplicateCode() {
        PropertyCategoryDTO dto = new PropertyCategoryDTO();
        dto.setCode("VIP");

        PropertyCategoryEntity entity = new PropertyCategoryEntity();
        entity.setCode("VIP");

        when(propertyCategoryConverter.toPropertyCategoryEntity(dto)).thenReturn(entity);
        when(propertyCategoryRepository.existsByCode("VIP")).thenReturn(true);

        assertThrows(DuplicateCodeException.class, () -> {
            propertyCategoryService.createOrUpdatePropertyCategory(dto);
        });

        verify(propertyCategoryRepository, times(1)).existsByCode("VIP");
    }

    @Test
    @DisplayName("deletePropertyCategory - Xóa cứng phân khúc theo ID và kiểm tra không còn trong DB")
    void deletePropertyCategory_Success() {
        doNothing().when(propertyCategoryRepository).deleteById(1);
        when(propertyCategoryRepository.findById(1)).thenReturn(null);

        propertyCategoryService.deletePropertyCategory(1);

        verify(propertyCategoryRepository, times(1)).deleteById(1);
        PropertyCategoryEntity found = propertyCategoryRepository.findById(1);
        assertNull(found);
    }
}
