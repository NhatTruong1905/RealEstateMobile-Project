package com.ndnt.repositories;

import com.ndnt.model.entity.InteractionEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InteractionRepository extends JpaRepository<InteractionEntity, Integer> {
    Page<InteractionEntity> findAllByStatus(Integer status, Pageable pageable);
}
