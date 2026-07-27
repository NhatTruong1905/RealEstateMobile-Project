package com.ndnt.repositories;

import com.ndnt.model.entity.FavoritePropertyEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface FavoritePropertyRepository extends JpaRepository<FavoritePropertyEntity, Integer> {
    List<FavoritePropertyEntity> findByUser_Id(Integer userId);

    boolean existsByUser_Id(Integer userId);

    void deleteAllByUser_Id(Integer userId);
}
