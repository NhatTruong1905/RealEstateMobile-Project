package com.ndnt.repositories;

import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.custom.UserRepositoryCustom;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<UserEntity, Integer>, UserRepositoryCustom {
    UserEntity getUserByUsername(String username);

}
