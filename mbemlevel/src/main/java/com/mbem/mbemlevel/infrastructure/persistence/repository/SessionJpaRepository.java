package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.SessionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface SessionJpaRepository extends JpaRepository<SessionJpaEntity, UUID> {

    List<SessionJpaEntity> findByCoursIdAndStatutNot(UUID coursId, String statut);

    @Query("SELECT s FROM SessionJpaEntity s " +
           "WHERE s.coursId = :coursId " +
           "AND s.statut = 'PLANIFIEE' " +
           "AND s.placesDisponibles > 0 " +
           "ORDER BY s.dateDebut ASC")
    List<SessionJpaEntity> findSessionsDisponibles(@Param("coursId") UUID coursId);

    /**
     * S20 — Détection de conflits horaires pour un formateur.
     * Vérifie si le formateur a déjà une session qui chevauche la période demandée.
     */
    @Query("SELECT COUNT(s) > 0 FROM SessionJpaEntity s " +
           "WHERE s.formateurId = :formateurId " +
           "AND s.statut NOT IN ('TERMINEE','ANNULEE') " +
           "AND s.dateDebut < :dateFin " +
           "AND s.dateFin > :dateDebut")
    boolean existsByFormateurIdAndPeriodeChevauchante(
        @Param("formateurId") UUID formateurId,
        @Param("dateDebut")   LocalDateTime dateDebut,
        @Param("dateFin")     LocalDateTime dateFin
    );

    List<SessionJpaEntity> findByFormateurId(UUID formateurId);
}
