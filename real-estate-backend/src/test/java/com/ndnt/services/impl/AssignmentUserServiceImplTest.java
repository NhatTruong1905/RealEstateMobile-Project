package com.ndnt.services.impl;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.entity.AssignmentUserEntity;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.AssignmentUserRepository;
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
public class AssignmentUserServiceImplTest {

    @Mock
    private AssignmentUserRepository assignmentUserRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private AssignmentUserServiceImpl assignmentUserService;

    @Test
    @DisplayName("createOrUpdateAssignment - Phân công nhân viên phụ trách người dùng")
    void createOrUpdateAssignment_Success() {
        AssignmentDTO dto = new AssignmentDTO();
        dto.setUserId(1);
        dto.setStaffIds(List.of(10));

        UserEntity user = new UserEntity();
        user.setId(1);

        UserEntity staff = new UserEntity();
        staff.setId(10);

        when(assignmentUserRepository.existsByUser_Id(1)).thenReturn(true);
        doNothing().when(assignmentUserRepository).deleteAllByUser_Id(1);
        doNothing().when(assignmentUserRepository).flush();

        when(userRepository.findById(1)).thenReturn(Optional.of(user));
        when(userRepository.findById(10)).thenReturn(Optional.of(staff));

        assignmentUserService.createOrUpdateAssignment(dto);

        verify(assignmentUserRepository, times(1)).deleteAllByUser_Id(1);
        verify(assignmentUserRepository, times(1)).save(any(AssignmentUserEntity.class));
    }

    @Test
    @DisplayName("getAssignedStaffIdsByUser - Lấy danh sách ID nhân viên phụ trách người dùng")
    void getAssignedStaffIdsByUser_Success() {
        UserEntity staff = new UserEntity();
        staff.setId(10);

        AssignmentUserEntity assignment = new AssignmentUserEntity();
        assignment.setStaff(staff);

        when(assignmentUserRepository.findByUser_Id(1)).thenReturn(List.of(assignment));

        List<Integer> result = assignmentUserService.getAssignedStaffIdsByUser(1);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(10, result.get(0));
        verify(assignmentUserRepository, times(1)).findByUser_Id(1);
    }

    @Test
    @DisplayName("isStaffOfUser - Kiểm tra nhân viên có phụ trách người dùng không")
    void isStaffOfUser_Success() {
        when(assignmentUserRepository.existsByStaff_IdAndUser_Id(10, 1)).thenReturn(true);

        boolean result = assignmentUserService.isStaffOfUser(10, 1);

        assertTrue(result);
        verify(assignmentUserRepository, times(1)).existsByStaff_IdAndUser_Id(10, 1);
    }
}
