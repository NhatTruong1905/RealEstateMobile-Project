package com.ndnt.services.impl;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.entity.*;
import com.ndnt.repositories.AssignmentInteractionRepository;
import com.ndnt.repositories.InteractionRepository;
import com.ndnt.repositories.UserRepository;
import com.ndnt.services.AssignmentInteractionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class AssignmentInteractionServiceImpl implements AssignmentInteractionService {
    @Autowired
    private AssignmentInteractionRepository assignmentInteractionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private InteractionRepository interactionRepository;

    @Override
    public void createOrUpdateAssignment(AssignmentDTO assignmentDTO) {
        if (this.assignmentInteractionRepository.existsByInteraction_Id(assignmentDTO.getInteractionId())) {
            this.assignmentInteractionRepository.deleteAllByInteraction_Id(assignmentDTO.getInteractionId());
            this.assignmentInteractionRepository.flush();
        }
        InteractionEntity p = this.interactionRepository.findById(assignmentDTO.getInteractionId()).get();
        for (Integer uId : assignmentDTO.getStaffIds()) {
            UserEntity u = this.userRepository.findById(uId).get();
            AssignmentInteractionEntity assignment = new AssignmentInteractionEntity();
            assignment.setInteraction(p);
            assignment.setStaff(u);
            this.assignmentInteractionRepository.save(assignment);
        }
    }

    @Override
    public List<Integer> getAssignedStaffIdsByInteraction(Integer interactionId) {
        List<AssignmentInteractionEntity> assignments = this.assignmentInteractionRepository.findByInteraction_Id(interactionId);

        return assignments.stream().map(assignment -> assignment.getStaff().getId())
                .collect(Collectors.toList());
    }

    @Override
    public boolean isStaffOfInteraction(Integer staffId, Integer id) {
        return this.assignmentInteractionRepository.existsByStaff_IdAndInteraction_Id(staffId, id);
    }
}
