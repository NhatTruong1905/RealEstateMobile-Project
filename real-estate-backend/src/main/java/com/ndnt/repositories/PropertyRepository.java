package com.ndnt.repositories;

import com.ndnt.model.entity.PropertyEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface PropertyRepository extends JpaRepository<PropertyEntity, Integer>, JpaSpecificationExecutor<PropertyEntity> {
}
