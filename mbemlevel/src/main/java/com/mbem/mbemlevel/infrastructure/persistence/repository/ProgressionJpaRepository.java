package com.mbem.mbemlevel.infrastructure.persistence.repository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.ProgressionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
public interface ProgressionJpaRepository extends JpaRepository<ProgressionJpaEntity, UUID> {
    Optional<ProgressionJpaEntity> findByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
    List<ProgressionJpaEntity>  findByApprenantId(UUID apprenantId);
    boolean existsByCoursId(UUID coursId);

    @Query("SELECT p, u FROM ProgressionJpaEntity p JOIN UtilisateurJpaEntity u ON p.apprenantId = u.id WHERE p.coursId = :coursId")
    List<Object[]> findApprenantsByCoursId(@Param("coursId") UUID coursId);
    /** Active le paiement d'un cours (estPaye=true) — utilisé après confirmation paiement. */
    @Modifying
    @Query("UPDATE ProgressionJpaEntity p SET p.estPaye = true " +
           "WHERE p.apprenantId = :uid AND p.coursId = :cid")
    int activerPaiement(@Param("uid") UUID apprenantId, @Param("cid") UUID coursId);

    @Query("SELECT COALESCE(AVG(p.pourcentage), 0.0) FROM ProgressionJpaEntity p WHERE p.coursId = :coursId")
    Double getAverageCompletionRateByCoursId(@Param("coursId") UUID coursId);

    long countByCoursId(UUID coursId);





    // Dans l'interface — décommenter :
@Query("SELECT p FROM ProgressionJpaEntity p " +
       "WHERE p.pourcentage >= p.seuilPaiementCours " +
       "AND p.estPaye = false " +
       "AND p.updatedAt BETWEEN :debut AND :fin")
List<ProgressionJpaEntity> findSeuilAtteintNonPayeEntre(
    @Param("debut") LocalDateTime debut,
    @Param("fin")   LocalDateTime fin
);

}
// ── Méthodes pour schedulers ─────────────────────────────────────────────────
// Ajouter dans ProgressionJpaRepository existant :

/*
    // S7 — SeuilNonConvertiScheduler : progressions ayant atteint le seuil hier, non payées
    @Query("SELECT p FROM ProgressionJpaEntity p " +
           "WHERE p.seuilAtteint = true AND p.estPaye = false " +
           "AND p.updatedAt BETWEEN :debut AND :fin")
    List<ProgressionJpaEntity> findSeuilAtteintNonPayeEntre(
        @Param("debut") LocalDateTime debut,
        @Param("fin")   LocalDateTime fin
    );
*/
