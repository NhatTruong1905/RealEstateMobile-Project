package com.ndnt.repositories;

import com.ndnt.model.entity.PropertyMailEvent;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.Instant;
import java.util.*;

public interface PropertyMailEventRepository extends JpaRepository<PropertyMailEvent,Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select e from PropertyMailEvent e where e.id=:id")
    Optional<PropertyMailEvent> findLocked(@Param("id") Long id);
    @Query("select e.id from PropertyMailEvent e where e.state='PENDING' and e.nextAttemptAt<=:now order by e.id")
    List<Long> due(@Param("now") Instant now, Pageable pageable);
    long countByPropertyId(Integer propertyId);
}
