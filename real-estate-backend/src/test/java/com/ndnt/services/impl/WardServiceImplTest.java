package com.ndnt.services.impl;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
import com.ndnt.converter.WardConverter;
import com.ndnt.model.dto.WardDTO;
import com.ndnt.model.entity.DistrictEntity;
import com.ndnt.model.entity.WardEntity;
import com.ndnt.repositories.WardRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class WardServiceImplTest {

    @Mock
    private WardRepository wardRepository;

    @Mock
    private WardConverter wardConverter;

    @InjectMocks
    private WardServiceImpl wardService;

    @Test
    @DisplayName("getWards - Lấy danh sách tất cả Phường/Xã")
    void getWards_Success() {
        DistrictEntity district = new DistrictEntity();
        district.setId(1);
        district.setName("Quận 1");
        district.setCode("Q1");

        WardEntity wardEntity = new WardEntity();
        wardEntity.setId(10);
        wardEntity.setName("Phường Bến Nghé");
        wardEntity.setDistrict(district);

        WardDTO wardDTO = new WardDTO();
        wardDTO.setId(10);
        wardDTO.setName("Phường Bến Nghé");

        when(wardRepository.findAll()).thenReturn(List.of(wardEntity));
        when(wardConverter.toWardDTO(wardEntity)).thenReturn(wardDTO);

        List<WardDTO> result = wardService.getWards();

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("Phường Bến Nghé", result.get(0).getName());
        assertEquals(1, result.get(0).getDistrictId());
        verify(wardRepository, times(1)).findAll();
    }

    @Test
    @DisplayName("findById - Tìm Phường/Xã theo ID")
    void findById_Success() {
        WardEntity wardEntity = new WardEntity();
        wardEntity.setId(10);
        WardDTO wardDTO = new WardDTO();
        wardDTO.setId(10);

        when(wardRepository.findById(10)).thenReturn(Optional.of(wardEntity));
        when(wardConverter.toWardDTO(wardEntity)).thenReturn(wardDTO);

        WardDTO result = wardService.findById(10);

        assertNotNull(result);
        assertEquals(10, result.getId());
        verify(wardRepository, times(1)).findById(10);
    }

    @Test
    @DisplayName("createOrUpdateWard - Ném DuplicateCodeException nếu mã code phường/xã đã tồn tại")
    void createOrUpdateWard_DuplicateCode() {
        WardDTO dto = new WardDTO();
        dto.setCode("P_BN");

        WardEntity entity = new WardEntity();
        entity.setCode("P_BN");

        when(wardConverter.toWardEntity(dto)).thenReturn(entity);
        when(wardRepository.existsByCode("P_BN")).thenReturn(true);

        assertThrows(DuplicateCodeException.class, () -> {
            wardService.createOrUpdateWard(dto);
        });

        verify(wardRepository, times(1)).existsByCode("P_BN");
    }

    @Test
    @DisplayName("deleteWard - Xóa cứng Phường/Xã theo ID và kiểm tra không còn trong DB")
    void deleteWard_Success() {
        doNothing().when(wardRepository).deleteById(10);
        when(wardRepository.findById(10)).thenReturn(Optional.empty());

        wardService.deleteWard(10);

        verify(wardRepository, times(1)).deleteById(10);
        Optional<WardEntity> found = wardRepository.findById(10);
        assertTrue(found.isEmpty());
    }
}
