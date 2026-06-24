package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.MoratoireJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface MoratoireJpaRepository extends JpaRepository<MoratoireJpaEntity, UUID> {
    List<MoratoireJpaEntity> findByStatut(String statut);
    Optional<MoratoireJpaEntity> findByPaiementIdAndStatut(UUID paiementId, String statut);
    List<MoratoireJpaEntity> findByPaiementId(UUID paiementId);
    boolean existsByPaiementIdAndStatut(UUID paiementId, String statut);
}
