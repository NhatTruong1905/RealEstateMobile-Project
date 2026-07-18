package com.ndnt.repositories;

import com.ndnt.model.entity.InteractionEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface InteractionRepository extends JpaRepository<InteractionEntity, Integer>, JpaSpecificationExecutor<InteractionEntity> {
    Page<InteractionEntity> findAllByStatus(Integer status, Pageable pageable);
}
