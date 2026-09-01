package com.ndnt.repositories;

import com.ndnt.model.dto.UserDTO;
import com.ndnt.model.entity.UserEntity;
import com.ndnt.repositories.custom.UserRepositoryCustom;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Date;
import java.util.List;

public interface UserRepository extends JpaRepository<UserEntity, Integer>, UserRepositoryCustom, JpaSpecificationExecutor<UserEntity> {
    UserEntity getUserByUsername(String username);

    Page<UserEntity> findAllByStatus(Integer status, Pageable pageable);

    List<UserEntity> findAllByStatusAndRole_Code(Integer status, String roleCode);

    boolean existsByUsername(String username);

    boolean existsByPhone(String phone);

    boolean existsByEmail(String email);

    UserEntity findByUsername(String username);

    UserEntity findByPhone(String phone);

    UserEntity findByEmail(String email);

    @Query("SELECT u FROM UserEntity u WHERE (u.username = :identifier OR u.phone = :identifier OR u.email = :identifier) AND (u.status = 1 OR u.status IS NULL)")
    UserEntity findByIdentifier(@Param("identifier") String identifier);

    UserEntity findByUsernameAndStatus(String username, Integer status);

    @Query("SELECT QUARTER(u.createdDate) AS quarter, COUNT(u) AS count " +
            "FROM UserEntity u " +
            "WHERE YEAR(u.createdDate) = :year " +
            "GROUP BY QUARTER(u.createdDate) " +
            "ORDER BY QUARTER(u.createdDate)")
    List<Object[]> countUsersByQuarterInYear(@Param("year") int year);
}
