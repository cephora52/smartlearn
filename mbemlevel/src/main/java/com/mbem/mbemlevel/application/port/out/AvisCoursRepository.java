package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.infrastructure.persistence.entity.AvisCoursJpaEntity;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AvisCoursRepository {
    AvisCoursJpaEntity save(AvisCoursJpaEntity avis);
    List<AvisCoursJpaEntity> findByCours(UUID coursId);
    Optional<AvisCoursJpaEntity> findByCoursAndApprenant(UUID coursId, UUID apprenantId);
    boolean existsByCoursAndApprenant(UUID coursId, UUID apprenantId);
    double calculerNoteMoyenne(UUID coursId);
    int compterAvisVerifies(UUID coursId);
}
