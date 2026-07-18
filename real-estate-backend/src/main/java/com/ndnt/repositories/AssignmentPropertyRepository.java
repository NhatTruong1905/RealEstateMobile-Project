package com.ndnt.repositories;

import com.ndnt.model.entity.AssignmentPropertyEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AssignmentPropertyRepository extends JpaRepository<AssignmentPropertyEntity, Integer> {
    boolean existsByProperty_Id(Integer propertyId);

    void deleteAllByProperty_Id(Integer id);

    List<AssignmentPropertyEntity> findByProperty_Id(Integer propertyId);

    boolean existsByStaff_IdAndProperty_Id(Integer staffId, Integer propertyId);
}
