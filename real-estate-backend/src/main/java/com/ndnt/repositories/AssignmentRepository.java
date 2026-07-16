package com.ndnt.repositories;

import com.ndnt.model.entity.AssignmentEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AssignmentRepository extends JpaRepository<AssignmentEntity, Integer> {
    boolean existsByProperty_Id(Integer propertyId);

    void deleteAllByProperty_Id(Integer id);

    List<AssignmentEntity> findByProperty_Id(Integer propertyId);
}
