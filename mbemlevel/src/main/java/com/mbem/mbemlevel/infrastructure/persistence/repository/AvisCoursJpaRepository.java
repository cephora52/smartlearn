package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.AvisCoursJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AvisCoursJpaRepository extends JpaRepository<AvisCoursJpaEntity, UUID> {
    List<AvisCoursJpaEntity> findByCoursId(UUID coursId);
    Optional<AvisCoursJpaEntity> findByCoursIdAndApprenantId(UUID coursId, UUID apprenantId);
    boolean existsByCoursIdAndApprenantId(UUID coursId, UUID apprenantId);

    @Query("SELECT AVG(a.note) FROM AvisCoursJpaEntity a WHERE a.coursId = :coursId AND a.estVerifie = true")
    Optional<Double> calculerNoteMoyenne(UUID coursId);

    @Query("SELECT COUNT(a) FROM AvisCoursJpaEntity a WHERE a.coursId = :coursId AND a.estVerifie = true")
    int compterAvisVerifies(UUID coursId);
}
