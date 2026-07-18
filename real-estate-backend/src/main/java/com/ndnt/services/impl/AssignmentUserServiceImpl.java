package com.ndnt.services.impl;

import com.ndnt.model.dto.AssignmentDTO;
import com.ndnt.model.entity.AssignmentInteractionEntity;
import com.ndnt.model.entity.AssignmentUserEntity;
import com.ndnt.model.entity.InteractionEntity;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.AssignmentUserRepository;
import com.ndnt.repositories.UserRepository;
import com.ndnt.services.AssignmentUserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class AssignmentUserServiceImpl implements AssignmentUserService {
    @Autowired
    private AssignmentUserRepository assignmentUserRepository;

    @Autowired
    private UserRepository userRepository;

    @Override
    public void createOrUpdateAssignment(AssignmentDTO assignmentDTO) {
        if (this.assignmentUserRepository.existsByUser_Id(assignmentDTO.getUserId())) {
            this.assignmentUserRepository.deleteAllByUser_Id(assignmentDTO.getUserId());
            this.assignmentUserRepository.flush();
        }
        UserEntity p = this.userRepository.findById(assignmentDTO.getUserId()).get();
        for (Integer uId : assignmentDTO.getStaffIds()) {
            UserEntity u = this.userRepository.findById(uId).get();
            AssignmentUserEntity assignment = new AssignmentUserEntity();
            assignment.setUser(p);
            assignment.setStaff(u);
            this.assignmentUserRepository.save(assignment);
        }
    }

    @Override
    public List<Integer> getAssignedStaffIdsByUser(Integer userId) {
        List<AssignmentUserEntity> assignments = this.assignmentUserRepository.findByUser_Id(userId);

        return assignments.stream().map(a -> a.getStaff().getId()).collect(Collectors.toList());
    }

    @Override
    public boolean isStaffOfUser(Integer staffId, Integer userid) {
        return this.assignmentUserRepository.existsByStaff_IdAndUser_Id(staffId, userid);
    }
}
