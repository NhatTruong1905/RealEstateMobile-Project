package com.ndnt.repositories;

import com.ndnt.model.entity.WardEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WardRepository extends JpaRepository<WardEntity, Integer> {
    boolean existsByCode(String code);
}
