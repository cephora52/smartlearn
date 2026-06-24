// MbemNova — application/usecase/auth/RenouvellerConfirmationEmailUseCase.java
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Use case : Régénérer et renvoyer le lien de confirmation email.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RenouvellerConfirmationEmailUseCase {

    private final UtilisateurRepository utilisateurRepo;
    private final AuditLogRepository auditRepo;
    private final EmailPort emailPort;

    @Value("${mbemnova.app.url:https://mbemnova.com}")
    private String appUrl;

    @Transactional
    public void executer(String email) {
        Utilisateur user = utilisateurRepo.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("USER_NOT_FOUND"));

        if (user.isEmailVerifie()) {
            throw new IllegalArgumentException("EMAIL_ALREADY_VERIFIED");
        }

        // Régénérer le token avec nouvelle expiration
        String nouveauToken = user.regenererTokenVerificationEmail();
        utilisateurRepo.save(user);

        // Renvoyer l'email
        emailPort.envoyerVerificationEmail(
            user.getEmail(),
            user.getPrenom(),
            appUrl + "/api/v1/auth/confirm-email?token=" + nouveauToken
        );

        auditRepo.enregistrer(user.getId(), user.getEmail(), "EMAIL_CONFIRMATION_RESENT",
            "UTILISATEUR", user.getId().toString(), null,
            "SUCCESS", null, null);

        log.info("[AUTH] Lien de confirmation renvoyé: {}", user.getEmail());
    }
}