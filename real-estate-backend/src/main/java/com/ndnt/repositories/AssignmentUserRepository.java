package com.ndnt.repositories;

import com.ndnt.model.entity.AssignmentInteractionEntity;
import com.ndnt.model.entity.AssignmentUserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AssignmentUserRepository extends JpaRepository<AssignmentUserEntity, Integer> {
    boolean existsByStaff_IdAndUser_Id(Integer staffId, Integer userId);

    List<AssignmentUserEntity> findByUser_Id(Integer userId);

    boolean existsByUser_Id(Integer userId);

    void deleteAllByUser_Id(Integer userId);
}
