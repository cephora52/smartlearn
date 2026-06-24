package com.mbem.mbemlevel.infrastructure.persistence.repository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.PaiementJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
public interface PaiementJpaRepository extends JpaRepository<PaiementJpaEntity, UUID> {
    Optional<PaiementJpaEntity> findByApprenantIdAndCoursId(UUID aid, UUID cid);
    List<PaiementJpaEntity>     findByApprenantId(UUID aid);
    /** Paiements en retard — pour le scheduler de relances. */
    @Query("SELECT p FROM PaiementJpaEntity p WHERE p.statut IN ('EN_ATTENTE','EN_RETARD') " +
           "AND p.accesActive = true")
    List<PaiementJpaEntity> findPaiementsEnCours();

    Optional<PaiementJpaEntity> findByIdAndApprenantId(UUID id, UUID apprenantId);
}
