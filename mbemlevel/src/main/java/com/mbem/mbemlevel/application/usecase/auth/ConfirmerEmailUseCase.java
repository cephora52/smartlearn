// MbemNova — application/usecase/auth/ConfirmerEmailUseCase.java
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.dto.response.AuthResultDto;
import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.application.usecase.auth.JwtFacade;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.time.LocalDateTime;

/**
 * Use case : Vérification de l'email après clic sur le lien de confirmation.
 * Renvoie les tokens pour authentifier immédiatement l'utilisateur.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ConfirmerEmailUseCase {

    private final UtilisateurRepository utilisateurRepo;
    private final AuditLogRepository auditRepo;
    private final JwtFacade jwtFacade;

    @Value("${mbemnova.security.refresh-token-ttl-jours:30}")
    private int refreshTtlJours;

    @Transactional
    public AuthResultDto executer(String token) {
        Utilisateur user = utilisateurRepo.findByTokenVerificationEmail(token)
                .orElseThrow(() -> new IllegalArgumentException("INVALID_EMAIL_CONFIRMATION_TOKEN"));

        // Vérifier si le token n'est pas expiré
        if (user.getTokenVerificationEmailExpireAt() == null ||
            user.getTokenVerificationEmailExpireAt().isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException("EMAIL_CONFIRMATION_TOKEN_EXPIRED");
        }

        user.verifierEmail();
        utilisateurRepo.save(user);
        auditRepo.enregistrer(user.getId(), user.getEmail(), "EMAIL_VERIFIED",
                "UTILISATEUR", user.getId().toString(), null,
                "SUCCESS", null, null);
        log.info("[AUTH] Email vérifié: {}", user.getEmail());

        String accessToken = jwtFacade.genererToken(
                user.getId().toString(), user.getEmail(), user.getRole().name());
        String refreshToken = jwtFacade.genererRefreshToken(
                user.getId(), refreshTtlJours, null, null);

        return new AuthResultDto(
                user.getId(), user.getNom(), user.getPrenom(), user.getEmail(),
                user.getRole().name(), accessToken, refreshToken,
                LocalDateTime.now().plusHours(24), !user.peutAccederAuxCours());
    }

}
