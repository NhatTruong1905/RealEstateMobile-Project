package com.ndnt.repositories;

import com.ndnt.model.entity.PropertyEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PropertyRepository extends JpaRepository<PropertyEntity, Integer> {
}
