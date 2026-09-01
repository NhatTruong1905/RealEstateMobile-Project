package com.ndnt.services.impl;

import com.cloudinary.Cloudinary;
import com.ndnt.converter.PropertyConverter;
import com.ndnt.model.dto.PropertyDTO;
import com.ndnt.model.entity.DistrictEntity;
import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.entity.WardEntity;
import com.ndnt.model.enums.StatusProperty;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.repositories.WardRepository;
import com.ndnt.services.ChatService;
import com.ndnt.services.FavoritePropertyService;
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
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class PropertyServiceImplTest {

    @Mock
    private PropertyRepository propertyRepository;

    @Mock
    private PropertyConverter propertyConverter;

    @Mock
    private FavoritePropertyService favoritePropertyService;

    @Mock
    private Cloudinary cloudinary;

    @Mock
    private ChatService chatService;

    @Mock
    private WardRepository wardRepository;

    @InjectMocks
    private PropertyServiceImpl propertyService;

    @Test
    @DisplayName("findById - Tìm thấy property theo ID")
    void findById_Success() {
        DistrictEntity district = new DistrictEntity();
        district.setName("Quận 1");

        WardEntity ward = new WardEntity();
        ward.setName("Bến Nghé");
        ward.setDistrict(district);

        PropertyEntity propertyEntity = new PropertyEntity();
        propertyEntity.setId(1);
        propertyEntity.setAddress("123 Lê Lợi");
        propertyEntity.setCity("Hồ Chí Minh");
        propertyEntity.setWard(ward);
        propertyEntity.setAssignments(new ArrayList<>());

        PropertyDTO propertyDTO = new PropertyDTO();
        propertyDTO.setId(1);
        propertyDTO.setTitle("Nhà mặt phố");

        when(propertyRepository.findById(1)).thenReturn(Optional.of(propertyEntity));
        when(propertyConverter.toPropertyDTO(propertyEntity)).thenReturn(propertyDTO);

        PropertyDTO result = propertyService.findById(1);

        assertNotNull(result);
        assertEquals(1, result.getId());
        assertEquals("Nhà mặt phố", result.getTitle());
        verify(propertyRepository, times(1)).findById(1);
    }

    @Test
    @DisplayName("deleteProperty - Xóa mềm bất động sản (status = DELETED)")
    void deleteProperty_Success() {
        PropertyEntity propertyEntity = new PropertyEntity();
        propertyEntity.setId(1);
        propertyEntity.setStatus(StatusProperty.PUBLISHED.getStatus());

        when(propertyRepository.findById(1)).thenReturn(Optional.of(propertyEntity));
        when(propertyRepository.save(propertyEntity)).thenReturn(propertyEntity);

        propertyService.deleteProperty(1);

        assertEquals(StatusProperty.DELETED.getStatus(), propertyEntity.getStatus());
        verify(propertyRepository, times(1)).save(propertyEntity);
    }

    @Test
    @DisplayName("getPropertyOfUser - Lấy danh sách tin của người dùng")
    void getPropertyOfUser_Success() {
        DistrictEntity district = new DistrictEntity();
        district.setName("Quận 1");

        WardEntity ward = new WardEntity();
        ward.setName("Bến Nghé");
        ward.setDistrict(district);

        PropertyEntity propertyEntity = new PropertyEntity();
        propertyEntity.setId(1);
        propertyEntity.setAddress("123 Lê Lợi");
        propertyEntity.setCity("Hồ Chí Minh");
        propertyEntity.setWard(ward);
        propertyEntity.setAssignments(new ArrayList<>());

        PropertyDTO propertyDTO = new PropertyDTO();
        propertyDTO.setId(1);

        when(propertyRepository.findByUser_IdOrderByIdDesc(10)).thenReturn(List.of(propertyEntity));
        when(propertyConverter.toPropertyDTO(propertyEntity)).thenReturn(propertyDTO);

        List<PropertyDTO> result = propertyService.getPropertyOfUser(10);

        assertNotNull(result);
        assertEquals(1, result.size());
        verify(propertyRepository, times(1)).findByUser_IdOrderByIdDesc(10);
    }
}
