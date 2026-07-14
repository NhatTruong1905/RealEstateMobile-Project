package com.ndnt.repositories;

import com.ndnt.model.entity.InteractionTypeEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InteractionTypeRepository extends JpaRepository<InteractionTypeEntity, Integer> {
    boolean existsByCode(String code);
}
