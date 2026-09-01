package com.ndnt.services.impl;

import com.ndnt.controlleradvices.exceptions.DuplicateCodeException;
import com.ndnt.converter.RoleConverter;
import com.ndnt.model.dto.RoleDTO;
import com.ndnt.model.entity.RoleEntity;
import com.ndnt.repositories.RoleRepository;
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
public class RoleServiceImplTest {

    @Mock
    private RoleRepository roleRepository;

    @Mock
    private RoleConverter roleConverter;

    @InjectMocks
    private RoleServiceImpl roleService;

    @Test
    @DisplayName("getRoles - Lấy danh sách tất cả vai trò")
    void getRoles_Success() {
        RoleEntity entity = new RoleEntity();
        entity.setId(1);
        entity.setCode("ROLE_ADMIN");

        RoleDTO dto = new RoleDTO();
        dto.setId(1);
        dto.setCode("ROLE_ADMIN");

        when(roleRepository.findAll(any(Sort.class))).thenReturn(List.of(entity));
        when(roleConverter.toRoleDTO(entity)).thenReturn(dto);

        List<RoleDTO> result = roleService.getRoles();

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals("ROLE_ADMIN", result.get(0).getCode());
        verify(roleRepository, times(1)).findAll(any(Sort.class));
    }

    @Test
    @DisplayName("findById - Tìm vai trò theo ID")
    void findById_Success() {
        RoleEntity entity = new RoleEntity();
        entity.setId(1);
        RoleDTO dto = new RoleDTO();
        dto.setId(1);

        when(roleRepository.findById(1)).thenReturn(Optional.of(entity));
        when(roleConverter.toRoleDTO(entity)).thenReturn(dto);

        RoleDTO result = roleService.findById(1);

        assertNotNull(result);
        assertEquals(1, result.getId());
        verify(roleRepository, times(1)).findById(1);
    }

    @Test
    @DisplayName("createOrUpdateRole - Ném DuplicateCodeException nếu mã vai trò đã tồn tại")
    void createOrUpdateRole_DuplicateCode() {
        RoleDTO dto = new RoleDTO();
        dto.setCode("ROLE_ADMIN");

        RoleEntity entity = new RoleEntity();
        entity.setCode("ROLE_ADMIN");

        when(roleConverter.toRoleEntity(dto)).thenReturn(entity);
        when(roleRepository.existsByCode("ROLE_ADMIN")).thenReturn(true);

        assertThrows(DuplicateCodeException.class, () -> {
            roleService.createOrUpdateRole(dto);
        });

        verify(roleRepository, times(1)).existsByCode("ROLE_ADMIN");
    }

    @Test
    @DisplayName("deleteRole - Xóa cứng vai trò theo ID và kiểm tra không còn trong DB")
    void deleteRole_Success() {
        doNothing().when(roleRepository).deleteById(1);
        when(roleRepository.findById(1)).thenReturn(Optional.empty());

        roleService.deleteRole(1);

        verify(roleRepository, times(1)).deleteById(1);
        Optional<RoleEntity> found = roleRepository.findById(1);
        assertTrue(found.isEmpty());
    }
}
