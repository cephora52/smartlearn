package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.CreneauJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface CreneauJpaRepository extends JpaRepository<CreneauJpaEntity, UUID> {
    List<CreneauJpaEntity> findBySessionId(UUID sessionId);
    List<CreneauJpaEntity> findBySessionIdAndPlacesRestantesGreaterThan(UUID sessionId, int minPlaces);
}
