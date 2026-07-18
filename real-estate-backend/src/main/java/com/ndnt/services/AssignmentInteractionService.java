package com.ndnt.services;

import com.ndnt.model.dto.AssignmentDTO;

import java.util.List;

public interface AssignmentInteractionService {
    void createOrUpdateAssignment(AssignmentDTO assignmentDTO);

    List<Integer> getAssignedStaffIdsByInteraction(Integer interactionId);

    boolean isStaffOfInteraction(Integer staffId, Integer id);
}
