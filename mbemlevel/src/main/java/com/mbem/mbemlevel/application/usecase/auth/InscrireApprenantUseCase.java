// =============================================================================
// MbemNova — application/usecase/auth/InscrireApprenantUseCase.java
//
// Use case : Inscription d'un nouvel apprenant (Scénario 02).
//
// Flux :
//   1. Vérifier unicité email (409 si existant)
//   2. Hacher le MDP avec BCrypt (cost 12)
//   3. Créer l'agrégat Utilisateur → enregistre ApprenantInscritEvent
//   4. Persister en base
//   5. Publier les domain events → email bienvenue
//   6. Générer JWT + Refresh Token
//   7. Audit
// =============================================================================
package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.dto.request.InscriptionCommand;
import com.mbem.mbemlevel.application.dto.response.AuthResultDto;
import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.application.port.out.RefreshTokenRepository;
import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

/**
 * Inscription d'un nouvel apprenant.
 * Respecte les scénarios de sécurité : rate limiting géré par RateLimitFilter,
 * protection anti-bot par honeypot (couche API).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class InscrireApprenantUseCase {

    private final UtilisateurRepository  utilisateurRepo;
    private final RefreshTokenRepository refreshTokenRepo;
    private final AuditLogRepository     auditRepo;
    private final PasswordEncoder        passwordEncoder;
    private final ApplicationEventPublisher eventPublisher;
    private final EmailPort emailPort;
    // JWT injecté depuis l'infrastructure via interface dans s07
    private final JwtFacade              jwtFacade;

    @Value("${mbemnova.security.refresh-token-ttl-jours:30}")
    private int refreshTtlJours;
    @Value("${mbemnova.app.url:https://mbemnova.com}")
    private String appUrl;

    /**
     * Exécute l'inscription.
     *
     * @param cmd Données validées par la couche API
     * @return Tokens JWT prêts à envoyer au client
     * @throws IllegalStateException si l'email est déjà utilisé
     */
    @Transactional
    public AuthResultDto executer(InscriptionCommand cmd) {

        // ── 1. Unicité email ────────────────────────────────────────────────
        if (utilisateurRepo.existsByEmail(cmd.email())) {
            auditRepo.enregistrer(null, cmd.email(), "REGISTER_FAILURE",
                "UTILISATEUR", null,
                Map.of("raison", "Email déjà utilisé"),
                "FAILURE", cmd.ipAdresse(), cmd.userAgent());
            // Exception métier → GlobalExceptionHandler retourne 409
            throw new IllegalStateException("EMAIL_ALREADY_EXISTS");
        }

        // ── 2. Hachage MDP (BCrypt cost=12 configuré dans PasswordConfig) ──
        String hashBcrypt = passwordEncoder.encode(cmd.motDePasse());

        // ── 3. Créer l'agrégat domaine ──────────────────────────────────────
        Utilisateur user = Utilisateur.creer(
            cmd.prenom(),
            cmd.nom(),
            cmd.email(),
            hashBcrypt,
            com.mbem.mbemlevel.domain.shared.enums.Role.valueOf(cmd.role()),
            cmd.telephone()
        );
        String tokenVerification = UUID.randomUUID().toString();
        // Token expire dans 24h pour sécurité
        LocalDateTime expireAt = LocalDateTime.now().plusHours(24);
        user.setTokenVerificationEmailAvecExpiration(tokenVerification, expireAt);

        // ── 4. Persister ─────────────────────────────────────────────────────
        Utilisateur saved = utilisateurRepo.save(user);

        // ── 5. Publier les domain events (email bienvenue, rappel 48h…) ────
        saved.getDomainEvents().forEach(eventPublisher::publishEvent);
        saved.clearDomainEvents();
        emailPort.envoyerVerificationEmail(
            saved.getEmail(),
            saved.getPrenom(),
            appUrl + "/api/v1/auth/confirm-email?token=" + tokenVerification
        );

        // ── 6. Générer les tokens (emailVerifie = true par défaut en dev) ────
        String accessToken  = jwtFacade.genererToken(
            saved.getId().toString(), saved.getEmail(), saved.getRole().name());
        String refreshToken = jwtFacade.genererRefreshToken(
            saved.getId(), refreshTtlJours, cmd.ipAdresse(), cmd.userAgent());

        // ── 7. Audit ─────────────────────────────────────────────────────────
        auditRepo.enregistrer(saved.getId(), saved.getEmail(), "REGISTER",
            "UTILISATEUR", saved.getId().toString(), null,
            "SUCCESS", cmd.ipAdresse(), cmd.userAgent());

        log.info("[AUTH] Inscription: {} ({})", saved.getPrenom(), saved.getEmail());

        return new AuthResultDto(
            saved.getId(), saved.getNom(), saved.getPrenom(), saved.getEmail(),
            saved.getRole().name(), accessToken, refreshToken,
            LocalDateTime.now().plusHours(24), false
        );
    }
}
