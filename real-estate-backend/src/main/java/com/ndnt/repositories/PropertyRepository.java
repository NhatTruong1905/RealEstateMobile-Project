package com.ndnt.repositories;

import com.ndnt.model.entity.PropertyEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface PropertyRepository extends JpaRepository<PropertyEntity, Integer>, JpaSpecificationExecutor<PropertyEntity> {
    List<PropertyEntity> findByStatus(String status);

    List<PropertyEntity> findById_In(Collection<Integer> ids);

    List<PropertyEntity> findByUser_Id(Integer userId);

    List<PropertyEntity> findByUser_IdOrderByIdDesc(Integer userId);
    
    @Query("SELECT QUARTER(p.createdDate) AS quarter, COUNT(p) AS count " +
            "FROM PropertyEntity p " +
            "WHERE YEAR(p.createdDate) = :year " +
            "GROUP BY QUARTER(p.createdDate) " +
            "ORDER BY QUARTER(p.createdDate)")
    List<Object[]> countPropertiesByQuarterInYear(@Param("year") int year);
}
