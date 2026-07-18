package com.ndnt.services;

import com.ndnt.model.dto.AssignmentDTO;

import java.util.List;

public interface AssignmentPropertyService {
    void createOrUpdateAssignment(AssignmentDTO assignmentDTO);

    List<Integer> getAssignedStaffIdsByProperty(Integer propertyId);

    boolean isStaffOfProperty(Integer staffId,Integer id);
}
