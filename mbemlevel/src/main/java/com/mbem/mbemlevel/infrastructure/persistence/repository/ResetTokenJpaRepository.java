// MbemNova — infrastructure/persistence/repository/ResetTokenJpaRepository.java
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.ResetTokenJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/** Repository tokens de reset MDP — usage unique, TTL 1h. */
public interface ResetTokenJpaRepository extends JpaRepository<ResetTokenJpaEntity, UUID> {

    /** Recherche un token valide (non utilisé, non expiré) par son hash. */
    @Query("SELECT r FROM ResetTokenJpaEntity r " +
           "WHERE r.tokenHache = :hash " +
           "AND r.estUtilise = false " +
           "AND r.expireLe > :maintenant")
    Optional<ResetTokenJpaEntity> findTokenValide(
        @Param("hash") String hash,
        @Param("maintenant") LocalDateTime maintenant
    );

    /** Invalide tous les tokens non utilisés d'un utilisateur. */
    @Modifying
    @Query("UPDATE ResetTokenJpaEntity r SET r.estUtilise = true " +
           "WHERE r.utilisateurId = :userId AND r.estUtilise = false")
    int invaliderTousTokensUtilisateur(@Param("userId") UUID userId);

    /** Nettoyage nocturne — tokens expirés ou utilisés. */
    @Modifying
    @Query("DELETE FROM ResetTokenJpaEntity r " +
           "WHERE r.expireLe < :maintenant OR r.estUtilise = true")
    int supprimerTokensExpires(@Param("maintenant") LocalDateTime maintenant);
}
