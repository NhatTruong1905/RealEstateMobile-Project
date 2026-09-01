package com.ndnt.services.impl;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
import com.ndnt.converter.DistrictConverter;
import com.ndnt.model.dto.DistrictDTO;
import com.ndnt.model.entity.DistrictEntity;
import com.ndnt.repositories.DistrictRepository;
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
public class DistrictServiceImplTest {

    @Mock
    private DistrictRepository districtRepository;

    @Mock
    private DistrictConverter districtConverter;

    @InjectMocks
    private DistrictServiceImpl districtService;

    @Test
    @DisplayName("getAllDistricts - Lấy tất cả Quận/Huyện")
    void getAllDistricts_Success() {
        DistrictEntity entity = new DistrictEntity();
        entity.setId(1);
        entity.setName("Quận 1");
        entity.setWards(new ArrayList<>());

        DistrictDTO dto = new DistrictDTO();
        dto.setId(1);
        dto.setName("Quận 1");

        when(districtRepository.findAll()).thenReturn(List.of(entity));
        when(districtConverter.toDistrictDTO(entity)).thenReturn(dto);

        List<DistrictDTO> result = districtService.getAllDistricts();

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Quận 1", result.get(0).getName());
        verify(districtRepository, times(1)).findAll();
    }

    @Test
    @DisplayName("findById - Tìm Quận/Huyện theo ID")
    void findById_Success() {
        DistrictEntity entity = new DistrictEntity();
        entity.setId(1);
        DistrictDTO dto = new DistrictDTO();
        dto.setId(1);

        when(districtRepository.findById(1)).thenReturn(Optional.of(entity));
        when(districtConverter.toDistrictDTO(entity)).thenReturn(dto);

        DistrictDTO result = districtService.findById(1);

        assertNotNull(result);
        assertEquals(1, result.getId());
        verify(districtRepository, times(1)).findById(1);
    }

    @Test
    @DisplayName("createOrUpdateDistrict - Ném DuplicateCodeException nếu mã code quận/huyện đã tồn tại")
    void createOrUpdateDistrict_DuplicateCode() {
        DistrictDTO dto = new DistrictDTO();
        dto.setCode("Q1");

        DistrictEntity entity = new DistrictEntity();
        entity.setCode("Q1");

        when(districtConverter.toDistrictEntity(dto)).thenReturn(entity);
        when(districtRepository.existsByCode("Q1")).thenReturn(true);

        assertThrows(DuplicateCodeException.class, () -> {
            districtService.createOrUpdateDistrict(dto);
        });

        verify(districtRepository, times(1)).existsByCode("Q1");
    }

    @Test
    @DisplayName("deleteDistrict - Xóa cứng Quận/Huyện theo ID và kiểm tra không còn trong DB")
    void deleteDistrict_Success() {
        doNothing().when(districtRepository).deleteById(1);
        when(districtRepository.findById(1)).thenReturn(Optional.empty());

        districtService.deleteDistrict(1);

        verify(districtRepository, times(1)).deleteById(1);
        Optional<DistrictEntity> found = districtRepository.findById(1);
        assertTrue(found.isEmpty());
    }
}
