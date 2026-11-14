package com.ndnt.repositories;

import com.ndnt.model.entity.PropertyIndexEvent;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Pageable;
import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.*;

public interface PropertyIndexEventRepository extends JpaRepository<PropertyIndexEvent, String> {
    @Query("select e.id from PropertyIndexEvent e where e.state='PENDING' and e.nextAttemptAt<=:now order by e.createdAt, e.id")
    List<String> due(@Param("now") Instant now, Pageable page);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select e from PropertyIndexEvent e where e.id=:id")
    Optional<PropertyIndexEvent> locked(@Param("id") String id);
}
