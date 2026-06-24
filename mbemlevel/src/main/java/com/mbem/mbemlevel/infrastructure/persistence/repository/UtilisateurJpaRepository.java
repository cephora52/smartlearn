// MbemNova — infrastructure/persistence/repository/UtilisateurJpaRepository.java
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.UtilisateurJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Repository Spring Data JPA pour les utilisateurs.
 * Les méthodes sensibles utilisent des requêtes JPQL explicites.
 */
public interface UtilisateurJpaRepository extends JpaRepository<UtilisateurJpaEntity, UUID> {

    /**
     * Recherche par email insensible à la casse.
     * Utilise l'index {@code idx_users_email_lower} de V9.
     */
    @Query("SELECT u FROM UtilisateurJpaEntity u WHERE LOWER(u.email) = LOWER(:email)")
    Optional<UtilisateurJpaEntity> findByEmailIgnoreCase(@Param("email") String email);

    /**
     * Vérifie l'existence sans charger l'entité complète.
     * COUNT(*) limité à 1 — plus performant que findByEmail.
     */
    @Query("SELECT COUNT(u) > 0 FROM UtilisateurJpaEntity u WHERE LOWER(u.email) = LOWER(:email)")
    boolean existsByEmailIgnoreCase(@Param("email") String email);

    /** Apprenants disponibles pour l'emploi — vitrine Talents (Scénario 14). */
    @Query("SELECT u FROM UtilisateurJpaEntity u " +
           "WHERE u.disponiblePourEmploi = true AND u.role = 'APPRENANT' " +
           "AND u.statut = 'ACTIF' ORDER BY u.xpTotal DESC")
    List<UtilisateurJpaEntity> findApprenantsDisponibles();


    // ✅ AJOUTER CETTE MÉTHODE - Version 1 : Query Method (recommandé)
    Optional<UtilisateurJpaEntity> findByTokenVerificationEmail(String token);


    @Query("SELECT u FROM UtilisateurJpaEntity u " +
       "WHERE u.statut = 'INSCRIT' " +
       "AND u.createdAt BETWEEN :debut AND :fin " +
       "AND NOT EXISTS (SELECT p FROM ProgressionJpaEntity p WHERE p.apprenantId = u.id)")
List<UtilisateurJpaEntity> findInscritsSansProgressionEntre(
    @Param("debut") LocalDateTime debut,
    @Param("fin")   LocalDateTime fin
);
}
