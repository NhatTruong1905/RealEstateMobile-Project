package com.ndnt.repositories;

import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.custom.UserRepositoryCustom;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserRepository extends JpaRepository<UserEntity, Integer>, UserRepositoryCustom {
    UserEntity getUserByUsername(String username);

    Page<UserEntity> findAllByStatus(Integer status, Pageable pageable);

    boolean existsByUsername(String username);

    boolean existsByPhone(String phone);

    boolean existsByEmail(String email);
}
