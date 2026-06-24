package com.mbem.mbemlevel.infrastructure.persistence.repository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.TrancheJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
public interface TrancheJpaRepository extends JpaRepository<TrancheJpaEntity, UUID> {
    List<TrancheJpaEntity> findByPaiementId(UUID paiementId);
    /** Tranches dues dans N jours (pour les relances préventives). */
    @Query("SELECT t FROM TrancheJpaEntity t WHERE t.statut = 'EN_ATTENTE' " +
           "AND t.dateEcheance BETWEEN :debut AND :fin")
    List<TrancheJpaEntity> findTranchesEcheantEntre(
        @Param("debut") LocalDate debut, @Param("fin") LocalDate fin);
    /** Tranches en retard (échéance dépassée, non payées). */
    @Query("SELECT t FROM TrancheJpaEntity t WHERE t.statut = 'EN_ATTENTE' " +
           "AND t.dateEcheance < :aujourd_hui")
    List<TrancheJpaEntity> findTranchesEnRetard(@Param("aujourd_hui") LocalDate aujourd_hui);
}
