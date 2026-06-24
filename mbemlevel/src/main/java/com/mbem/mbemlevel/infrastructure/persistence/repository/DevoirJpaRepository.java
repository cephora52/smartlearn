package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.DevoirJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface DevoirJpaRepository extends JpaRepository<DevoirJpaEntity, UUID> {
    List<DevoirJpaEntity> findBySessionId(UUID sessionId);
    List<DevoirJpaEntity> findBySessionIdAndEstVerrouilleIsFalse(UUID sessionId);

    // Devoirs dont la deadline approche dans les 24h (pour rappel S11)
    List<DevoirJpaEntity> findByDateRemiseBetweenAndEstVerrouilleIsFalse(
        LocalDateTime debut, LocalDateTime fin);
}