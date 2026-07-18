package com.ndnt.services;

import com.ndnt.model.dto.AssignmentDTO;

import java.util.List;

public interface AssignmentUserService {
    void createOrUpdateAssignment(AssignmentDTO assignmentDTO);

    List<Integer> getAssignedStaffIdsByUser(Integer userId);

    boolean isStaffOfUser(Integer staffId, Integer userid);
}
