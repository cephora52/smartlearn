// =============================================================================
// MbemNova — application/usecase/auth/RefreshTokenUseCase.java
// Rotation sécurisée : valide l'ancien token → révoque → génère nouveau.
// =============================================================================
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.dto.response.AuthResultDto;
import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

/** Rotation du refresh token — génère un nouveau JWT et un nouveau RT. */
@Service
@RequiredArgsConstructor
@Slf4j
public class RefreshTokenUseCase {

    private final UtilisateurRepository utilisateurRepo;
    private final AuditLogRepository    auditRepo;
    private final JwtFacade             jwtFacade;

    @Value("${mbemnova.security.refresh-token-ttl-jours:30}")
    private int refreshTtlJours;

    @Transactional
    public AuthResultDto executer(String refreshTokenBrut, String ip, String userAgent) {

        // 1. Valider et effectuer la rotation (révoque l'ancien token en interne)
        UUID utilisateurId = jwtFacade.validerRefreshTokenEtRoter(refreshTokenBrut)
            .orElseThrow(() -> {
                log.warn("[AUTH] Refresh token invalide ou expiré depuis IP: {}", ip);
                return new SecurityException("INVALID_REFRESH_TOKEN");
            });

        // 2. Charger l'utilisateur
        Utilisateur user = utilisateurRepo.findById(utilisateurId)
            .orElseThrow(() -> new SecurityException("USER_NOT_FOUND"));

        // 3. Vérifier le compte
        if (user.estBloque()) throw new SecurityException("ACCOUNT_TEMPORARILY_LOCKED");

        // 4. Générer nouveau JWT + nouveau refresh token
        String newAccessToken  = jwtFacade.genererToken(
            user.getId().toString(), user.getEmail(), user.getRole().name());
        String newRefreshToken = jwtFacade.genererRefreshToken(
            user.getId(), refreshTtlJours, ip, userAgent);

        auditRepo.enregistrer(user.getId(), user.getEmail(), "TOKEN_REFRESHED",
            "UTILISATEUR", user.getId().toString(),
            Map.of("ip", ip != null ? ip : "unknown"),
            "SUCCESS", ip, userAgent);

        log.debug("[AUTH] Refresh token roté pour: {}", user.getEmail());

        return new AuthResultDto(
            user.getId(), user.getNom(), user.getPrenom(), user.getEmail(),
            user.getRole().name(), newAccessToken, newRefreshToken,
            LocalDateTime.now().plusHours(24),
            !user.peutAccederAuxCours()
        );
    }
}
