package com.ndnt.services.impl;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.entity.AssignmentPropertyEntity;
import com.ndnt.model.entity.PropertyEntity;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.AssignmentPropertyRepository;
import com.ndnt.repositories.PropertyRepository;
import com.ndnt.repositories.UserRepository;
import com.ndnt.services.AssignmentPropertyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class AssignmentPropertyServiceImpl implements AssignmentPropertyService {
    @Autowired
    private AssignmentPropertyRepository assignmentPropertyRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PropertyRepository propertyRepository;

    @Override
    public void createOrUpdateAssignment(AssignmentDTO assignmentDTO) {
        if (this.assignmentPropertyRepository.existsByProperty_Id(assignmentDTO.getPropertyId())) {
            this.assignmentPropertyRepository.deleteAllByProperty_Id(assignmentDTO.getPropertyId());
            this.assignmentPropertyRepository.flush();
        }
        PropertyEntity p = this.propertyRepository.findById(assignmentDTO.getPropertyId()).get();
        for (Integer uId : assignmentDTO.getStaffIds()) {
            UserEntity u = this.userRepository.findById(uId).get();
            AssignmentPropertyEntity assignment = new AssignmentPropertyEntity();
            assignment.setProperty(p);
            assignment.setStaff(u);
            this.assignmentPropertyRepository.save(assignment);
        }
    }

    @Override
    public List<Integer> getAssignedStaffIdsByProperty(Integer propertyId) {
        List<AssignmentPropertyEntity> assignments = this.assignmentPropertyRepository.findByProperty_Id(propertyId);

        return assignments.stream()
                .map(assignment -> assignment.getStaff().getId())
                .collect(Collectors.toList());
    }

    @Override
    public boolean isStaffOfProperty(Integer staffId, Integer properTyId) {
        return this.assignmentPropertyRepository.existsByStaff_IdAndProperty_Id(staffId, properTyId);
    }
}
