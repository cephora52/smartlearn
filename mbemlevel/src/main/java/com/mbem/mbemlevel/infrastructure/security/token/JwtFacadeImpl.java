// =============================================================================
// MbemNova — infrastructure/security/token/JwtFacadeImpl.java
//
// Implémentation de l'interface JwtFacade définie dans la couche Application.
// Cette classe "colle" les services JWT de l'infrastructure à l'interface
// attendue par les use cases — principe d'inversion de dépendance.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.security.token;

import com.mbem.mbemlevel.application.usecase.auth.JwtFacade;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

/**
 * Implémentation de {@link JwtFacade} — expose les services tokens
 * de l'infrastructure à la couche Application sans couplage direct.
 */
@Component
@RequiredArgsConstructor
public class JwtFacadeImpl implements JwtFacade {

    private final JwtTokenProvider          jwtProvider;
    private final TokenBlacklistService     blacklistService;
    private final RefreshTokenService       refreshTokenService;
    private final ResetPasswordTokenService resetTokenService;

    // ── Access Token ─────────────────────────────────────────────────────────

    @Override
    public String genererToken(String userId, String email, String role) {
        return jwtProvider.genererToken(userId, email, role);
    }

    @Override
    public void blacklister(String accessToken) {
        blacklistService.blacklister(accessToken);
    }

    // ── Refresh Token ─────────────────────────────────────────────────────────

    @Override
    public String genererRefreshToken(UUID utilisateurId, int ttlJours,
                                      String ip, String userAgent) {
        return refreshTokenService.generer(utilisateurId, ttlJours, ip, userAgent);
    }

    @Override
    public Optional<UUID> validerRefreshTokenEtRoter(String refreshTokenBrut) {
        return refreshTokenService.validerEtRoter(refreshTokenBrut);
    }

    @Override
    public void revoquerRefreshToken(String refreshTokenBrut) {
        refreshTokenService.revoquer(refreshTokenBrut);
    }

    @Override
    public void revoquerTousRefreshTokens(UUID utilisateurId) {
        refreshTokenService.revoquerTous(utilisateurId);
    }

    // ── Reset Token ───────────────────────────────────────────────────────────

    @Override
    public String genererResetToken(UUID utilisateurId, int ttlMinutes, String ip) {
        return resetTokenService.generer(utilisateurId, ttlMinutes, ip);
    }

    @Override
    public String hacherTokenReset(String tokenBrut) {
        return resetTokenService.hacher(tokenBrut);
    }
}
