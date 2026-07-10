// =============================================================================
// MbemNova — application/usecase/auth/ConnecterUtilisateurUseCase.java
//
// Use case : Connexion (Scénario 03).
//
// RÈGLES DE SÉCURITÉ CRITIQUES :
//   - Message d'erreur GÉNÉRIQUE (ne révèle pas si l'email existe)
//   - Compteur d'échecs incrémenté en base
//   - Blocage temporaire après N échecs (configurable)
//   - Toutes les tentatives sont auditées avec l'IP
//   - Un compte SUSPENDU peut se connecter mais l'accès cours est bloqué
// =============================================================================
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.dto.request.ConnexionCommand;
import com.mbem.mbemlevel.application.dto.response.AuthResultDto;
import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import com.mbem.mbemlevel.application.port.out.RefreshTokenRepository;
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

/**
 * Connexion sécurisée avec protection brute-force.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ConnecterUtilisateurUseCase {

    private final UtilisateurRepository  utilisateurRepo;
    private final RefreshTokenRepository refreshTokenRepo;
    private final AuditLogRepository     auditRepo;
    private final PasswordEncoder        passwordEncoder;
    private final JwtFacade              jwtFacade;

    @Value("${mbemnova.security.max-tentatives-connexion:5}")
    private int maxTentatives;

    @Value("${mbemnova.security.blocage-connexion-minutes:30}")
    private int dureeBlockageMinutes;

    @Value("${mbemnova.security.refresh-token-ttl-jours:30}")
    private int refreshTtlJours;

    /**
     * Message générique — NE JAMAIS indiquer si l'email existe ou non.
     * Prévient l'énumération des comptes (account enumeration attack).
     */
    private static final String ERR_GENERIQUE = "INVALID_CREDENTIALS";

    @Transactional
    public AuthResultDto executer(ConnexionCommand cmd) {

        // ── 1. Chercher l'utilisateur ────────────────────────────────────────
        Utilisateur user = utilisateurRepo.findByEmail(cmd.email())
            .orElseGet(() -> {
                // Email inexistant — même log et même message que MDP incorrect
                auditRepo.enregistrer(null, cmd.email(), "LOGIN_FAILURE",
                    "UTILISATEUR", null,
                    Map.of("raison", "Email inexistant", "ip", nullSafe(cmd.ipAdresse())),
                    "FAILURE", cmd.ipAdresse(), cmd.userAgent());
                throw new SecurityException(ERR_GENERIQUE);
            });

        // ── 2. Vérifier le blocage brute-force ───────────────────────────────
        if (user.estBloque()) {
            auditRepo.enregistrer(user.getId(), user.getEmail(), "LOGIN_BLOCKED",
                "UTILISATEUR", user.getId().toString(),
                Map.of("bloqueJusquA", String.valueOf(user.getBloqueJusquAu())),
                "WARNING", cmd.ipAdresse(), cmd.userAgent());
            throw new SecurityException("ACCOUNT_TEMPORARILY_LOCKED");
        }

        // ── 3. Vérifier le mot de passe ─────────────────────────────────────
        if (!passwordEncoder.matches(cmd.motDePasse(), user.getMotDePasseHache())) {
            user.enregistrerConnexionEchouee(maxTentatives, dureeBlockageMinutes);
            utilisateurRepo.save(user);

            auditRepo.enregistrer(user.getId(), user.getEmail(), "LOGIN_FAILURE",
                "UTILISATEUR", user.getId().toString(),
                Map.of("tentatives", user.getTentativesEchouees(),
                       "ip", nullSafe(cmd.ipAdresse())),
                "FAILURE", cmd.ipAdresse(), cmd.userAgent());

            log.warn("[AUTH] Échec connexion #{}: {}", user.getTentativesEchouees(), user.getEmail());
            throw new SecurityException(ERR_GENERIQUE);
        }

        if (!user.isEmailVerifie()) {
            auditRepo.enregistrer(user.getId(), user.getEmail(), "LOGIN_BLOCKED_EMAIL_NOT_VERIFIED",
                "UTILISATEUR", user.getId().toString(),
                Map.of("ip", nullSafe(cmd.ipAdresse())),
                "WARNING", cmd.ipAdresse(), cmd.userAgent());
            throw new SecurityException("EMAIL_NOT_VERIFIED");
        }

        // ── 4. Enregistrer la connexion réussie ─────────────────────────────
        user.enregistrerConnexionReussie();
        utilisateurRepo.save(user);

        // ── 5. Générer les tokens ─────────────────────────────────────────────
        String accessToken  = jwtFacade.genererToken(
            user.getId().toString(), user.getEmail(), user.getRole().name());

        // Si rememberMe, le TTL est configuré plus long (déjà géré dans JwtFacade)
        String refreshToken = jwtFacade.genererRefreshToken(
            user.getId(), cmd.rememberMe() ? refreshTtlJours : 1,
            cmd.ipAdresse(), cmd.userAgent());

        // ── 6. Audit ─────────────────────────────────────────────────────────
        auditRepo.enregistrer(user.getId(), user.getEmail(), "LOGIN_SUCCESS",
            "UTILISATEUR", user.getId().toString(),
            Map.of("ip", nullSafe(cmd.ipAdresse())),
            "SUCCESS", cmd.ipAdresse(), cmd.userAgent());

        log.info("[AUTH] Connexion réussie: {}", user.getEmail());

        return new AuthResultDto(
            user.getId(), user.getNom(), user.getPrenom(), user.getEmail(),
            user.getRole().name(), accessToken, refreshToken,
            LocalDateTime.now().plusHours(24),
            !user.peutAccederAuxCours()  // estSuspendu
        );
    }

    private static String nullSafe(String s) {
        return s != null ? s : "unknown";
    }
}
