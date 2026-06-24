// =============================================================================
// MbemNova — application/usecase/auth/JwtFacade.java
//
// Interface facade JWT définie dans la couche Application.
// Implémentée dans la couche Infrastructure (s07).
// Évite la dépendance circulaire Application → Infrastructure.
// =============================================================================
package com.mbem.mbemlevel.application.usecase.auth;

import java.util.Optional;
import java.util.UUID;

/**
 * Facade JWT exposée à la couche Application.
 * Abstrait toutes les opérations JWT et tokens derrière une interface simple.
 */
public interface JwtFacade {

    // ── Access Token ─────────────────────────────────────────────────────────

    /** Génère un JWT signé HS256 avec claims userId, email, role. */
    String genererToken(String userId, String email, String role);

    /** Ajoute le JWT dans la blacklist Redis (TTL = durée restante du token). */
    void blacklister(String accessToken);

    // ── Refresh Token ─────────────────────────────────────────────────────────

    /**
     * Génère un refresh token sécurisé (256 bits aléatoires).
     * Persiste le SHA-256 en base — retourne le token brut.
     */
    String genererRefreshToken(UUID utilisateurId, int ttlJours,
                               String ip, String userAgent);

    /**
     * Valide un refresh token et effectue la rotation.
     * Révoque l'ancien token, retourne l'ID utilisateur associé.
     */
    Optional<UUID> validerRefreshTokenEtRoter(String refreshTokenBrut);

    /** Révoque un refresh token spécifique. */
    void revoquerRefreshToken(String refreshTokenBrut);

    /** Révoque TOUS les refresh tokens d'un utilisateur. */
    void revoquerTousRefreshTokens(UUID utilisateurId);

    // ── Reset Token ───────────────────────────────────────────────────────────

    /**
     * Génère un token de reset MDP (256 bits aléatoires).
     * Persiste le SHA-256 en base — retourne le token brut.
     */
    String genererResetToken(UUID utilisateurId, int ttlMinutes, String ip);

    /** Calcule le SHA-256 d'un token brut (pour les lookups en base). */
    String hacherTokenReset(String tokenBrut);
}
