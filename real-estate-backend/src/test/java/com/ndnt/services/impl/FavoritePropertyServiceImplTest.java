package com.ndnt.services.impl;

import com.ndnt.converter.FavoritePropertyConverter;
import com.ndnt.model.dto.FavoritePropertyDTO;
import com.ndnt.model.entity.FavoritePropertyEntity;
import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.FavoritePropertyRepository;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.repositories.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class FavoritePropertyServiceImplTest {

    @Mock
    private FavoritePropertyRepository favoritePropertyRepository;

    @Mock
    private FavoritePropertyConverter favoritePropertyConverter;

    @Mock
    private PropertyRepository propertyRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private FavoritePropertyServiceImpl favoritePropertyService;

    @Test
    @DisplayName("getFavoritePropertyIdsByUserId - Lấy danh sách ID bất động sản yêu thích theo User ID")
    void getFavoritePropertyIdsByUserId_Success() {
        PropertyEntity propertyEntity = new PropertyEntity();
        propertyEntity.setId(10);

        FavoritePropertyEntity favoritePropertyEntity = new FavoritePropertyEntity();
        favoritePropertyEntity.setProperty(propertyEntity);

        when(favoritePropertyRepository.findByUser_Id(1)).thenReturn(List.of(favoritePropertyEntity));

        List<Integer> result = favoritePropertyService.getFavoritePropertyIdsByUserId(1);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(10, result.get(0));
        verify(favoritePropertyRepository, times(1)).findByUser_Id(1);
    }

    @Test
    @DisplayName("createOrUpdateFavoriteProperty - Thêm tin bất động sản yêu thích")
    void createOrUpdateFavoriteProperty_Success() {
        FavoritePropertyDTO dto = new FavoritePropertyDTO();
        dto.setUserId(1);
        dto.setPropertyIds(List.of(10, 20));

        UserEntity user = new UserEntity();
        user.setId(1);

        PropertyEntity p1 = new PropertyEntity();
        p1.setId(10);
        PropertyEntity p2 = new PropertyEntity();
        p2.setId(20);

        when(favoritePropertyRepository.existsByUser_Id(1)).thenReturn(true);
        doNothing().when(favoritePropertyRepository).deleteAllByUser_Id(1);
        doNothing().when(favoritePropertyRepository).flush();
        when(userRepository.findById(1)).thenReturn(Optional.of(user));
        when(propertyRepository.findById(10)).thenReturn(Optional.of(p1));
        when(propertyRepository.findById(20)).thenReturn(Optional.of(p2));

        favoritePropertyService.createOrUpdateFavoriteProperty(dto);

        verify(favoritePropertyRepository, times(1)).deleteAllByUser_Id(1);
        verify(favoritePropertyRepository, times(2)).save(any(FavoritePropertyEntity.class));
    }
}
