package com.ndnt.services.impl;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.entity.AssignmentPropertyEntity;
import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.AssignmentPropertyRepository;
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
public class AssignmentPropertyServiceImplTest {

    @Mock
    private AssignmentPropertyRepository assignmentPropertyRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PropertyRepository propertyRepository;

    @InjectMocks
    private AssignmentPropertyServiceImpl assignmentPropertyService;

    @Test
    @DisplayName("createOrUpdateAssignment - Phân công nhân viên quản lý bất động sản")
    void createOrUpdateAssignment_Success() {
        AssignmentDTO dto = new AssignmentDTO();
        dto.setPropertyId(1);
        dto.setStaffIds(List.of(10));

        PropertyEntity property = new PropertyEntity();
        property.setId(1);

        UserEntity staff = new UserEntity();
        staff.setId(10);

        when(assignmentPropertyRepository.existsByProperty_Id(1)).thenReturn(true);
        doNothing().when(assignmentPropertyRepository).deleteAllByProperty_Id(1);
        doNothing().when(assignmentPropertyRepository).flush();

        when(propertyRepository.findById(1)).thenReturn(Optional.of(property));
        when(userRepository.findById(10)).thenReturn(Optional.of(staff));

        assignmentPropertyService.createOrUpdateAssignment(dto);

        verify(assignmentPropertyRepository, times(1)).deleteAllByProperty_Id(1);
        verify(assignmentPropertyRepository, times(1)).save(any(AssignmentPropertyEntity.class));
    }

    @Test
    @DisplayName("getAssignedStaffIdsByProperty - Lấy danh sách ID nhân viên quản lý bất động sản")
    void getAssignedStaffIdsByProperty_Success() {
        UserEntity staff = new UserEntity();
        staff.setId(10);

        AssignmentPropertyEntity assignment = new AssignmentPropertyEntity();
        assignment.setStaff(staff);

        when(assignmentPropertyRepository.findByProperty_Id(1)).thenReturn(List.of(assignment));

        List<Integer> result = assignmentPropertyService.getAssignedStaffIdsByProperty(1);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(10, result.get(0));
        verify(assignmentPropertyRepository, times(1)).findByProperty_Id(1);
    }

    @Test
    @DisplayName("isStaffOfProperty - Kiểm tra nhân viên có quản lý bất động sản không")
    void isStaffOfProperty_Success() {
        when(assignmentPropertyRepository.existsByStaff_IdAndProperty_Id(10, 1)).thenReturn(true);

        boolean result = assignmentPropertyService.isStaffOfProperty(10, 1);

        assertTrue(result);
        verify(assignmentPropertyRepository, times(1)).existsByStaff_IdAndProperty_Id(10, 1);
    }
}
