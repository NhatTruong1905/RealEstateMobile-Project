package com.ndnt.repositories;

import com.ndnt.model.entity.InteractionEntity;
import com.ndnt.model.entity.UserEntity;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface InteractionRepository extends JpaRepository<InteractionEntity, Integer>, JpaSpecificationExecutor<InteractionEntity> {
    List<InteractionEntity> findByProperty_IdAndSender_Id(Integer propertyId, Integer senderId);

    List<InteractionEntity> findByReceiver_IdOrderByIdDesc(Integer receiverId);

    List<InteractionEntity> findByReceiver_IdAndStatusOrderByIdDesc(Integer receiverId, Integer status);

    List<InteractionEntity> findByProperty_IdAndSender_IdAndReceiver_IdAndInteractionType_Id(Integer propertyId, Integer senderId, Integer receiverId, Integer interactionTypeId);

    @Modifying
    @Transactional
    @Query("UPDATE InteractionEntity i SET i.status = 0 " +
            "WHERE i.property.id = :propertyId " +
            "AND i.sender.id = :senderId " +
            "AND i.receiver.id = :receiverId " +
            "AND i.interactionType.id IN :typeIds")
    void updateStatusToZeroForSpecificTypes(
            @Param("propertyId") Integer propertyId,
            @Param("senderId") Integer senderId,
            @Param("receiverId") Integer receiverId,
            @Param("typeIds") List<Integer> typeIds
    );

    @Query("SELECT QUARTER(i.createdDate) AS quarter, COUNT(i) AS count " +
            "FROM InteractionEntity i " +
            "WHERE YEAR(i.createdDate) = :year " +
            "GROUP BY QUARTER(i.createdDate) " +
            "ORDER BY QUARTER(i.createdDate)")
    List<Object[]> countInteractionsByQuarterInYear(@Param("year") int year);
}
