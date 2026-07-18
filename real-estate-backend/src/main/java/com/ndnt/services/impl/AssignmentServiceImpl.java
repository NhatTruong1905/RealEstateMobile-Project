package com.ndnt.services.impl;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.entity.AssignmentEntity;
import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.AssignmentRepository;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.repositories.UserRepository;
import com.ndnt.services.AssignmentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class AssignmentServiceImpl implements AssignmentService {
    @Autowired
    private AssignmentRepository assignmentRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PropertyRepository propertyRepository;

    @Override
    public void createOrUpdateAssignment(AssignmentDTO assignmentDTO) {
        if (this.assignmentRepository.existsByProperty_Id(assignmentDTO.getPropertyId())) {
            this.assignmentRepository.deleteAllByProperty_Id(assignmentDTO.getPropertyId());
            this.assignmentRepository.flush();
        }
        PropertyEntity p = this.propertyRepository.findById(assignmentDTO.getPropertyId()).get();
        for (Integer uId : assignmentDTO.getStaffIds()) {
            UserEntity u = this.userRepository.findById(uId).get();
            AssignmentEntity assignment = new AssignmentEntity();
            assignment.setProperty(p);
            assignment.setStaff(u);
            this.assignmentRepository.save(assignment);
        }

    }

    @Override
    public List<Integer> getAssignedStaffIdsByProperty(Integer propertyId) {
        List<AssignmentEntity> assignments = this.assignmentRepository.findByProperty_Id(propertyId);

        return assignments.stream()
                .map(assignment -> assignment.getStaff().getId())
                .collect(Collectors.toList());
    }

    @Override
    public boolean isStaffOfProperty(Integer staffId, Integer properTyId) {
        return this.assignmentRepository.existsByStaff_IdAndProperty_Id(staffId, properTyId);
    }
}
