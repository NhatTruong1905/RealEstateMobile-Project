package com.ndnt.repositories;

import com.ndnt.model.entity.RoleEntity;
import jakarta.validation.constraints.NotNull;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoleRepository extends JpaRepository<RoleEntity, Integer> {
    boolean existsByCode(String code);

    RoleEntity getByCode(String code);
}
