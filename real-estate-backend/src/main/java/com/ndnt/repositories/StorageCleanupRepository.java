package com.ndnt.repositories;

import com.ndnt.model.entity.StorageCleanupTask;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.time.Instant;
import java.util.*;

public interface StorageCleanupRepository extends JpaRepository<StorageCleanupTask, Long> {
    @Query("select t.id from StorageCleanupTask t where t.provider=:provider and t.state in ('PENDING', 'RETAINED') and t.nextAttemptAt <= :now order by t.id")
    List<Long> due(@Param("provider") String provider, @Param("now") Instant now, Pageable pageable);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select t from StorageCleanupTask t where t.id=:id")
    Optional<StorageCleanupTask> findLocked(@Param("id") Long id);
}
