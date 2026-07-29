package com.ndnt.repositories;

import com.ndnt.model.entity.InteractionTypeEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface InteractionTypeRepository extends JpaRepository<InteractionTypeEntity, Integer> {
    boolean existsByCode(String code);

    InteractionTypeEntity findFirstByCode(String code);
}
