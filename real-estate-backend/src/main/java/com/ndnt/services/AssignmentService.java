package com.ndnt.services;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.entity.AssignmentEntity;

import java.util.List;

public interface AssignmentService {
    void createOrUpdateAssignment(AssignmentDTO assignmentDTO);

    List<Integer> getAssignedStaffIdsByProperty(Integer propertyId);
}
