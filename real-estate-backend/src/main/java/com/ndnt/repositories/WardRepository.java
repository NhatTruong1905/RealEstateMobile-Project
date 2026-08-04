package com.ndnt.repositories;

import com.ndnt.model.entity.WardEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface WardRepository extends JpaRepository<WardEntity, Integer> {
    boolean existsByCode(String code);

    @Query("SELECT w FROM WardEntity w WHERE LOWER(w.name) LIKE LOWER(CONCAT('%', :wardName, '%'))")
    Optional<WardEntity> findFirstByMatchingName(@Param("wardName") String wardName);
}
