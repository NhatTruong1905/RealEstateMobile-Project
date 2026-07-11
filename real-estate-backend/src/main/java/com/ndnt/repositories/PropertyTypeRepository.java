package com.ndnt.repositories;

import com.ndnt.model.entity.PropertyTypeEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PropertyTypeRepository extends JpaRepository<PropertyTypeEntity, Integer> {
    PropertyTypeEntity findById(int id);
}
