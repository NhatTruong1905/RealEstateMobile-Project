package com.ndnt.repositories;

import com.ndnt.model.entity.DistrictEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DistrictRepository extends JpaRepository<DistrictEntity, Integer> {
    boolean existsByCode(String code);
}
