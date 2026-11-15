package com.ndnt.repositories;

import com.ndnt.model.entity.PropertyEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface PropertyRepository extends JpaRepository<PropertyEntity, Integer>, JpaSpecificationExecutor<PropertyEntity> {
    @Query("select p from PropertyEntity p where p.id > :after order by p.id")
    List<PropertyEntity> indexPage(@Param("after") Integer after, org.springframework.data.domain.Pageable page);
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from PropertyEntity p where p.id = :id")
    java.util.Optional<PropertyEntity> findLockedById(@Param("id") Integer id);

    List<PropertyEntity> findByStatus(String status);

    List<PropertyEntity> findById_In(Collection<Integer> ids);

    List<PropertyEntity> findByUser_Id(Integer userId);

    List<PropertyEntity> findByUser_IdOrderByIdDesc(Integer userId);

    @EntityGraph(attributePaths = {"user", "type", "category", "ward", "ward.district"})
    Page<PropertyEntity> findByUser_IdOrderByIdDesc(Integer userId, Pageable pageable);
    
    @Query("SELECT QUARTER(p.createdDate) AS quarter, COUNT(p) AS count " +
            "FROM PropertyEntity p " +
            "WHERE YEAR(p.createdDate) = :year " +
            "GROUP BY QUARTER(p.createdDate) " +
            "ORDER BY QUARTER(p.createdDate)")
    List<Object[]> countPropertiesByQuarterInYear(@Param("year") int year);
}
