package com.mbem.mbemlevel.infrastructure.persistence.repository;

/**
 * PATCH — Méthodes à ajouter dans ProgressionJpaRepository :
 *
 * // S7 — SeuilNonConvertiScheduler
 * @Query("SELECT p FROM ProgressionJpaEntity p " +
 *        "WHERE p.seuilAtteint = true AND p.estPaye = false " +
 *        "AND p.updatedAt BETWEEN :debut AND :fin")
 * List<ProgressionJpaEntity> findSeuilAtteintNonPayeEntre(
 *     @Param("debut") LocalDateTime debut,
 *     @Param("fin")   LocalDateTime fin);
 *
 * // S5 — Reprise dernière leçon
 * Optional<ProgressionJpaEntity> findByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
 *
 * // S25 — Stats admin
 * @Query("SELECT COUNT(p) FROM ProgressionJpaEntity p " +
 *        "WHERE p.estPaye = true AND p.createdAt >= :depuis")
 * long countPayesSince(@Param("depuis") LocalDateTime depuis);
 *
 * // S2 — RappelInscriptionScheduler
 * @Query("SELECT u FROM UtilisateurJpaEntity u " +
 *        "WHERE u.createdAt BETWEEN :debut AND :fin " +
 *        "AND u.id NOT IN (SELECT DISTINCT p.apprenantId FROM ProgressionJpaEntity p)")
 * List<UtilisateurJpaEntity> findInscritsSansProgressionEntre(...)
 * → Cette méthode va dans UtilisateurJpaRepository
 */
public final class ProgressionJpaRepositoryPatch {
    private ProgressionJpaRepositoryPatch() {}
}
