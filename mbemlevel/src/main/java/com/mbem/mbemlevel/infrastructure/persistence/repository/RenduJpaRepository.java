package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.RenduJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RenduJpaRepository extends JpaRepository<RenduJpaEntity, UUID> {
    Optional<RenduJpaEntity> findByDevoirIdAndApprenantId(UUID devoirId, UUID apprenantId);
    List<RenduJpaEntity>     findByDevoirId(UUID devoirId);
    List<RenduJpaEntity>     findByApprenantId(UUID apprenantId);
    boolean                  existsByDevoirIdAndApprenantId(UUID devoirId, UUID apprenantId);

    // Pour le tableau de bord formateur (S22)
    @Query("SELECT COUNT(r) FROM RenduJpaEntity r WHERE r.devoirId = :devoirId")
    int countByDevoirId(UUID devoirId);

    @Query("SELECT COUNT(r) FROM RenduJpaEntity r WHERE r.devoirId = :devoirId AND r.enRetard = true")
    int countEnRetardByDevoirId(UUID devoirId);
}
