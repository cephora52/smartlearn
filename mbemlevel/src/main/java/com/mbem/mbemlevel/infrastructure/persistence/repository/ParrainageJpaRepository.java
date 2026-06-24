package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.ParrainageJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ParrainageJpaRepository extends JpaRepository<ParrainageJpaEntity, UUID> {
    Optional<ParrainageJpaEntity> findByCodeParrainage(String code);
    List<ParrainageJpaEntity> findByParrainId(UUID parrainId);
    Optional<ParrainageJpaEntity> findByFilleulId(UUID filleulId);
    long countByParrainIdAndStatut(UUID parrainId, String statut);
}
