package com.ndnt.repositories;

import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.custom.UserRepositoryCustom;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserRepository extends JpaRepository<UserEntity, Integer>, UserRepositoryCustom {
    UserEntity getUserByUsername(String username);

    List<UserEntity> findAllByStatusOrderByIdDesc(Integer status);

    UserEntity getUserByEmail(String email);
}
