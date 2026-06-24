// =============================================================================
// MbemNova — application/usecase/auth/ReinitialiserMotDePasseUseCase.java
//
// Use case : Réinitialisation du mot de passe en 2 étapes (Scénario 27).
//
// ÉTAPE 1 — Demande (demanderReset) :
//   - Chercher l'utilisateur par email
//   - Si trouvé : générer token (SHA-256 en base, brut dans l'email)
//   - Toujours retourner le même message (protection énumération comptes)
//
// ÉTAPE 2 — Confirmation (confirmerReset) :
//   - Valider le token (non utilisé, non expiré)
//   - Hacher le nouveau MDP
//   - Mettre à jour l'utilisateur
//   - Révoquer TOUS les refresh tokens (sécurité : invalider toutes sessions)
//   - Audit
// =============================================================================
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.application.port.out.ResetTokenRepository;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

/**
 * Réinitialisation MDP — 2 étapes sécurisées.
 * Protection contre l'énumération de comptes : même réponse si email connu ou inconnu.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ReinitialiserMotDePasseUseCase {

    private final UtilisateurRepository utilisateurRepo;
    private final ResetTokenRepository  resetTokenRepo;
    private final EmailPort             emailPort;
    private final PasswordEncoder       passwordEncoder;
    private final AuditLogRepository    auditRepo;
    private final JwtFacade             jwtFacade;

    @Value("${mbemnova.app.url:https://mbemnova.com}")
    private String appUrl;

    @Value("${mbemnova.security.reset-token-ttl-minutes:60}")
    private int ttlMinutes;

    // ── Étape 1 : Demander le reset ──────────────────────────────────────────

    /**
     * Envoie un lien de reset si l'email existe.
     * Retourne silencieusement si l'email n'existe pas (protection énumération).
     *
     * @param email      Email soumis par l'utilisateur
     * @param ipAdresse  IP pour l'audit et le rate limiting
     */
    @Transactional
    public void demanderReset(String email, String ipAdresse) {
        utilisateurRepo.findByEmail(email).ifPresent(user -> {
            // Invalider les anciens tokens non utilisés
            resetTokenRepo.invaliderTousTokensUtilisateur(user.getId());

            // Générer et persister le token
            String tokenBrut = jwtFacade.genererResetToken(
                user.getId(), ttlMinutes, ipAdresse);

            // Construire le lien de reset
            String lien = appUrl + "/reset-password?token=" + tokenBrut;

            // Envoyer l'email
            emailPort.envoyerResetMotDePasse(user.getEmail(), user.getPrenom(), lien);

            auditRepo.enregistrer(user.getId(), email, "PASSWORD_RESET_REQUESTED",
                "UTILISATEUR", user.getId().toString(),
                Map.of("ip", ipAdresse != null ? ipAdresse : "unknown"),
                "SUCCESS", ipAdresse, null);

            log.info("[AUTH] Lien reset envoyé à: {}", email);
        });
        // Si email inexistant : pas d'erreur, même réponse → impossible de savoir
    }

    // ── Étape 2 : Confirmer avec le nouveau MDP ──────────────────────────────

    /**
     * Applique le nouveau mot de passe après validation du token.
     *
     * @param tokenBrut      Token reçu dans le lien email
     * @param nouveauMdpClair Nouveau mot de passe EN CLAIR
     */
    @Transactional
    public void confirmerReset(String tokenBrut, String nouveauMdpClair) {

        // 1. Valider et consommer le token (usage unique)
        UUID utilisateurId = resetTokenRepo.findUtilisateurIdSiValide(
                tokenBrut != null ? jwtFacade.hacherTokenReset(tokenBrut) : "",
                LocalDateTime.now())
            .orElseThrow(() -> new SecurityException("INVALID_OR_EXPIRED_RESET_TOKEN"));

        // 2. Charger l'utilisateur
        Utilisateur user = utilisateurRepo.findById(utilisateurId)
            .orElseThrow(() -> new SecurityException("USER_NOT_FOUND"));

        // 3. Hacher et appliquer le nouveau MDP
        String nouveauHash = passwordEncoder.encode(nouveauMdpClair);
        user.changerMotDePasse(nouveauHash);
        utilisateurRepo.save(user);

        // 4. Marquer le token comme utilisé
        resetTokenRepo.marquerUtilise(jwtFacade.hacherTokenReset(tokenBrut));

        // 5. Révoquer TOUS les refresh tokens (invalider toutes les sessions actives)
        jwtFacade.revoquerTousRefreshTokens(utilisateurId);

        auditRepo.enregistrer(utilisateurId, user.getEmail(), "PASSWORD_RESET_DONE",
            "UTILISATEUR", utilisateurId.toString(), null,
            "SUCCESS", null, null);

        log.info("[AUTH] MDP réinitialisé pour: {}", user.getEmail());
    }
}
