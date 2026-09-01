package com.ndnt.services.impl;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.entity.AssignmentInteractionEntity;
import com.ndnt.model.entity.InteractionEntity;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.AssignmentInteractionRepository;
import com.ndnt.repositories.InteractionRepository;
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
public class AssignmentInteractionServiceImplTest {

    @Mock
    private AssignmentInteractionRepository assignmentInteractionRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private InteractionRepository interactionRepository;

    @InjectMocks
    private AssignmentInteractionServiceImpl assignmentInteractionService;

    @Test
    @DisplayName("createOrUpdateAssignment - Phân công nhân viên phụ trách tương tác")
    void createOrUpdateAssignment_Success() {
        AssignmentDTO dto = new AssignmentDTO();
        dto.setInteractionId(1);
        dto.setStaffIds(List.of(10, 20));

        InteractionEntity interaction = new InteractionEntity();
        interaction.setId(1);

        UserEntity staff1 = new UserEntity();
        staff1.setId(10);
        UserEntity staff2 = new UserEntity();
        staff2.setId(20);

        when(assignmentInteractionRepository.existsByInteraction_Id(1)).thenReturn(true);
        doNothing().when(assignmentInteractionRepository).deleteAllByInteraction_Id(1);
        doNothing().when(assignmentInteractionRepository).flush();

        when(interactionRepository.findById(1)).thenReturn(Optional.of(interaction));
        when(userRepository.findById(10)).thenReturn(Optional.of(staff1));
        when(userRepository.findById(20)).thenReturn(Optional.of(staff2));

        assignmentInteractionService.createOrUpdateAssignment(dto);

        verify(assignmentInteractionRepository, times(1)).deleteAllByInteraction_Id(1);
        verify(assignmentInteractionRepository, times(2)).save(any(AssignmentInteractionEntity.class));
    }

    @Test
    @DisplayName("getAssignedStaffIdsByInteraction - Lấy danh sách ID nhân viên phụ trách")
    void getAssignedStaffIdsByInteraction_Success() {
        UserEntity staff = new UserEntity();
        staff.setId(10);

        AssignmentInteractionEntity assignment = new AssignmentInteractionEntity();
        assignment.setStaff(staff);

        when(assignmentInteractionRepository.findByInteraction_Id(1)).thenReturn(List.of(assignment));

        List<Integer> result = assignmentInteractionService.getAssignedStaffIdsByInteraction(1);

        assertNotNull(result);
        assertEquals(1, result.size());
        assertEquals(10, result.get(0));
        verify(assignmentInteractionRepository, times(1)).findByInteraction_Id(1);
    }

    @Test
    @DisplayName("isStaffOfInteraction - Kiểm tra nhân viên có phụ trách tương tác không")
    void isStaffOfInteraction_Success() {
        when(assignmentInteractionRepository.existsByStaff_IdAndInteraction_Id(10, 1)).thenReturn(true);

        boolean result = assignmentInteractionService.isStaffOfInteraction(10, 1);

        assertTrue(result);
        verify(assignmentInteractionRepository, times(1)).existsByStaff_IdAndInteraction_Id(10, 1);
    }
}
