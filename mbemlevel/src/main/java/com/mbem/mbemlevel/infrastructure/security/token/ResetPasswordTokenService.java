// =============================================================================
// MbemNova — infrastructure/security/token/ResetPasswordTokenService.java
// Tokens reset MDP : usage unique, TTL 1h, SHA-256 en base.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.security.token;

import com.mbem.mbemlevel.application.port.out.ResetTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.Optional;
import java.util.UUID;

/**
 * Tokens de reset MDP — sécurisés et à usage unique.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ResetPasswordTokenService {

    private final ResetTokenRepository repository;
    private static final SecureRandom  SECURE_RANDOM = new SecureRandom();

    /**
     * Génère un token de reset et l'enregistre (hash SHA-256 en base).
     *
     * @param utilisateurId Utilisateur concerné
     * @param ttlMinutes    Durée de validité (60 min par défaut)
     * @param ip            IP de la demande
     * @return Token brut à inclure dans le lien email
     */
    @Transactional
    public String generer(UUID utilisateurId, int ttlMinutes, String ip) {
        // Invalider les anciens tokens non utilisés
        repository.invaliderTousTokensUtilisateur(utilisateurId);

        // Générer token sécurisé
        byte[] bytes = new byte[32];
        SECURE_RANDOM.nextBytes(bytes);
        String tokenBrut = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);

        repository.sauvegarder(
            utilisateurId,
            hacher(tokenBrut),
            LocalDateTime.now().plusMinutes(ttlMinutes),
            ip
        );
        log.debug("[RESET-TOKEN] Token généré pour utilisateur {}", utilisateurId);
        return tokenBrut;
    }

    /**
     * Valide et consomme un token (marque comme utilisé — usage unique).
     *
     * @return ID utilisateur si valide, empty si invalide/expiré/déjà utilisé
     */
    @Transactional
    public Optional<UUID> validerEtConsommer(String tokenBrut) {
        if (tokenBrut == null || tokenBrut.isBlank()) return Optional.empty();

        String hash = hacher(tokenBrut);
        Optional<UUID> uid = repository.findUtilisateurIdSiValide(hash, LocalDateTime.now());

        if (uid.isPresent()) {
            repository.marquerUtilise(hash);
            log.debug("[RESET-TOKEN] Token consommé pour utilisateur {}", uid.get());
        } else {
            log.warn("[RESET-TOKEN] Token invalide, expiré ou déjà utilisé");
        }
        return uid;
    }

    /** SHA-256 d'un token en Base64 URL-safe. */
    public String hacher(String token) {
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256")
                .digest(token.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(hash);
        } catch (Exception e) {
            throw new RuntimeException("Erreur hachage token reset", e);
        }
    }
}
