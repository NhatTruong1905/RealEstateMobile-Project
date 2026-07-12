package com.ndnt.repositories;

import com.ndnt.model.entity.PropertyCategoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PropertyCategoryRepository extends JpaRepository<PropertyCategoryEntity, Integer> {
    PropertyCategoryEntity findById(int id);

    void deleteById(int id);

    boolean existsByCode(String code);
}
