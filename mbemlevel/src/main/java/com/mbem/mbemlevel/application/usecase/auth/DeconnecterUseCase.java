// =============================================================================
// MbemNova — application/usecase/auth/DeconnecterUseCase.java
// Déconnexion sécurisée : blacklist JWT + révocation refresh token.
// =============================================================================
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Déconnexion sécurisée.
 * Le JWT est blacklisté dans Redis avec TTL = durée restante du token.
 * Le refresh token est révoqué en base.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DeconnecterUseCase {

    private final AuditLogRepository auditRepo;
    private final JwtFacade          jwtFacade;

    @Transactional
    public void executer(UUID utilisateurId, String email,
                         String accessToken, String refreshTokenBrut) {

        // 1. Blacklister le JWT courant (TTL = durée restante du token)
        if (accessToken != null && !accessToken.isBlank()) {
            jwtFacade.blacklister(accessToken);
        }

        // 2. Révoquer le refresh token
        if (refreshTokenBrut != null && !refreshTokenBrut.isBlank()) {
            jwtFacade.revoquerRefreshToken(refreshTokenBrut);
        }

        auditRepo.enregistrer(utilisateurId, email, "LOGOUT",
            "UTILISATEUR", utilisateurId != null ? utilisateurId.toString() : null,
            null, "SUCCESS", null, null);

        log.info("[AUTH] Déconnexion: {}", email);
    }
}
