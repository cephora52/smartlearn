// =============================================================================
// MbemNova — application/port/out/RefreshTokenRepository.java
// Port sortant pour la gestion des refresh tokens avec rotation sécurisée.
// =============================================================================
package com.mbem.mbemlevel.application.port.out;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/**
 * Port sortant — refresh tokens avec rotation et blacklist.
 *
 * <h3>Principe de la rotation</h3>
 * <pre>
 * Login  → genererEtSauvegarder() → retourne token brut au client
 * Refresh → findUtilisateurByTokenHache() → revoquerToken() → nouveau token
 * Logout  → revoquerToken()
 * </pre>
 *
 * <p>Le token brut n'est jamais stocké — seulement son SHA-256.</p>
 */
public interface RefreshTokenRepository {

    /**
     * Persiste un nouveau refresh token.
     *
     * @param utilisateurId Propriétaire du token
     * @param tokenHache    SHA-256 du token brut
     * @param expireLe      Date d'expiration (30 jours par défaut)
     * @param ip            IP de création (traçabilité)
     * @param userAgent     User-Agent du navigateur
     */
    void sauvegarder(UUID utilisateurId, String tokenHache,
                     LocalDateTime expireLe, String ip, String userAgent);

    /**
     * Cherche l'utilisateur associé à un hash de token.
     * Retourne empty si : token révoqué, expiré, ou inexistant.
     */
    Optional<UUID> findUtilisateurIdByTokenHache(String tokenHache);

    /** Révoque un token spécifique (après rotation ou logout). */
    void revoquerToken(String tokenHache);

    /**
     * Révoque TOUS les tokens actifs d'un utilisateur.
     * Utilisé lors d'un changement de MDP ou d'une suspension.
     *
     * @return Nombre de tokens révoqués
     */
    int revoquerTousLesTokens(UUID utilisateurId);

    /**
     * Supprime les tokens expirés et révoqués.
     * Appelé par le scheduler de nettoyage nocturne.
     *
     * @return Nombre de tokens supprimés
     */
    int nettoyerTokensExpires();
}
