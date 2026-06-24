// MbemNova — infrastructure/persistence/repository/RefreshTokenJpaRepository.java
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.RefreshTokenJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/** Repository refresh tokens avec opérations de rotation et nettoyage. */
public interface RefreshTokenJpaRepository extends JpaRepository<RefreshTokenJpaEntity, UUID> {

    /** Recherche par hash — appelé à chaque refresh token. */
    Optional<RefreshTokenJpaEntity> findByTokenHache(String tokenHache);

    /**
     * Révoque tous les tokens actifs d'un utilisateur.
     * Utilisé lors d'un changement de MDP ou suspension.
     */
    @Modifying
    @Query("UPDATE RefreshTokenJpaEntity r SET r.estRevoque = true " +
           "WHERE r.utilisateurId = :userId AND r.estRevoque = false")
    int revoquerTousTokensUtilisateur(@Param("userId") UUID userId);

    /**
     * Supprime les tokens expirés ET révoqués.
     * Scheduler quotidien — libère de l'espace en base.
     */
    @Modifying
    @Query("DELETE FROM RefreshTokenJpaEntity r " +
           "WHERE r.expireLe < :maintenant OR r.estRevoque = true")
    int supprimerTokensExpiresetRevoques(@Param("maintenant") LocalDateTime maintenant);
}
