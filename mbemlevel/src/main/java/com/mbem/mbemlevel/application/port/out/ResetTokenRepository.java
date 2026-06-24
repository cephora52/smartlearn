// =============================================================================
// MbemNova — application/port/out/ResetTokenRepository.java
// Port sortant pour les tokens de réinitialisation de mot de passe.
// =============================================================================
package com.mbem.mbemlevel.application.port.out;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/**
 * Port sortant — tokens de reset MDP.
 * Usage unique, TTL 1 heure, hash SHA-256 en base.
 */
public interface ResetTokenRepository {

    /** Persiste un nouveau token de reset (remplace les anciens non utilisés). */
    void sauvegarder(UUID utilisateurId, String tokenHache,
                     LocalDateTime expireLe, String ip);

    /**
     * Recherche un token valide (non utilisé, non expiré) par son hash.
     */
    Optional<UUID> findUtilisateurIdSiValide(String tokenHache, LocalDateTime maintenant);

    /**
     * Marque un token comme utilisé (usage unique — invalide immédiatement).
     */
    void marquerUtilise(String tokenHache);

    /**
     * Invalide tous les tokens non utilisés d'un utilisateur.
     * Appelé avant de créer un nouveau token (on ne génère qu'un à la fois).
     */
    int invaliderTousTokensUtilisateur(UUID utilisateurId);

    /** Nettoyage des tokens expirés — scheduler quotidien. */
    int nettoyerTokensExpires();
}
