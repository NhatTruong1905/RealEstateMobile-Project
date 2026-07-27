package com.ndnt.repositories;

import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.custom.UserRepositoryCustom;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.List;

public interface UserRepository extends JpaRepository<UserEntity, Integer>, UserRepositoryCustom, JpaSpecificationExecutor<UserEntity> {
    UserEntity getUserByUsername(String username);

    Page<UserEntity> findAllByStatus(Integer status, Pageable pageable);

    List<UserEntity> findAllByStatusAndRole_Code(Integer status, String roleCode);

    boolean existsByUsername(String username);

    boolean existsByPhone(String phone);

    boolean existsByEmail(String email);

    UserEntity findByUsername(String username);

    UserEntity findByUsernameAndStatus(String username, Integer status);
}
