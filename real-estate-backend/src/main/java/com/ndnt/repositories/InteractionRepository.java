package com.ndnt.repositories;

import com.ndnt.model.entity.InteractionEntity;
import com.ndnt.model.entity.UserEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.List;

public interface InteractionRepository extends JpaRepository<InteractionEntity, Integer>, JpaSpecificationExecutor<InteractionEntity> {
    Page<InteractionEntity> findAllByStatus(Integer status, Pageable pageable);

    List<InteractionEntity> findByProperty_IdAndSender(Integer propertyId, UserEntity sender);

    List<InteractionEntity> findByProperty_IdAndSender_Id(Integer propertyId, Integer senderId);
}
