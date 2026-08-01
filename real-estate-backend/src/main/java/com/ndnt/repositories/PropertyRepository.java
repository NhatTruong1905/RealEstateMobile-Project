package com.ndnt.repositories;

import com.ndnt.model.entity.PropertyEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.Collection;
import java.util.List;

public interface PropertyRepository extends JpaRepository<PropertyEntity, Integer>, JpaSpecificationExecutor<PropertyEntity> {
    List<PropertyEntity> findByStatus(String status);

    List<PropertyEntity> findById_In(Collection<Integer> ids);

    List<PropertyEntity> findByUser_Id(Integer userId);
}
