package com.ndnt.repositories;

import com.ndnt.model.entity.AssignmentInteractionEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AssignmentInteractionRepository extends JpaRepository<AssignmentInteractionEntity, Integer> {
    boolean existsByStaff_IdAndInteraction_Id(Integer staffId, Integer interactionId);

    List<AssignmentInteractionEntity> findByInteraction_Id(Integer interactionId);

    boolean existsByInteraction_Id(Integer interactionId);

    void deleteAllByInteraction_Id(Integer interactionId);
}
