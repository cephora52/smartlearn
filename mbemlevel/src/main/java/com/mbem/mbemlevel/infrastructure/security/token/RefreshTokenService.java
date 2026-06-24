// =============================================================================
// MbemNova — infrastructure/security/token/RefreshTokenService.java
//
// Gestion des refresh tokens avec rotation sécurisée.
// Token brut = 256 bits aléatoires (SecureRandom).
// SHA-256 stocké en base — jamais le token brut.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.security.token;

import com.mbem.mbemlevel.application.port.out.RefreshTokenRepository;
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
 * Service refresh tokens avec rotation sécurisée.
 *
 * <h3>Cycle de rotation</h3>
 * <pre>
 * Login  → generer() → retourne token brut au client (cookie HttpOnly)
 * Refresh → validerEtRoter() → révoque l'ancien → retourne nouveau token brut
 * Logout  → revoquerToken()
 * MDP change → revoquerTous()
 * </pre>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RefreshTokenService {

    private final RefreshTokenRepository repository;
    private static final SecureRandom    SECURE_RANDOM = new SecureRandom();

    /**
     * Génère et persiste un nouveau refresh token.
     *
     * @param utilisateurId Propriétaire
     * @param ttlJours      Durée de vie en jours
     * @param ip            IP de création
     * @param userAgent     User-Agent
     * @return Token brut à transmettre au client (jamais stocké en clair en base)
     */
    @Transactional
    public String generer(UUID utilisateurId, int ttlJours, String ip, String userAgent) {
        // Générer 256 bits aléatoires → token brut URL-safe Base64
        byte[] bytes = new byte[32];
        SECURE_RANDOM.nextBytes(bytes);
        String tokenBrut = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);

        // Calculer l'expiration
        LocalDateTime expireLe = LocalDateTime.now().plusDays(ttlJours);

        // Persister uniquement le SHA-256
        repository.sauvegarder(utilisateurId, hacher(tokenBrut), expireLe, ip, userAgent);
        log.debug("[REFRESH] Token généré pour utilisateur {}", utilisateurId);

        return tokenBrut; // Retourner le brut au client uniquement
    }

    /**
     * Valide un token et effectue la rotation.
     * L'ancien token est révoqué, l'ID utilisateur est retourné.
     *
     * @param tokenBrut Token reçu du client
     * @return ID utilisateur si valide, empty sinon
     */
    @Transactional
    public Optional<UUID> validerEtRoter(String tokenBrut) {
        if (tokenBrut == null || tokenBrut.isBlank()) return Optional.empty();

        String hash  = hacher(tokenBrut);
        Optional<UUID> uid = repository.findUtilisateurIdByTokenHache(hash);

        if (uid.isPresent()) {
            repository.revoquerToken(hash); // Rotation : invalider l'ancien
            log.debug("[REFRESH] Rotation effectuée pour utilisateur {}", uid.get());
        } else {
            log.warn("[REFRESH] Token invalide ou expiré");
        }
        return uid;
    }

    /** Révoque un token spécifique (logout). */
    @Transactional
    public void revoquer(String tokenBrut) {
        if (tokenBrut != null && !tokenBrut.isBlank()) {
            repository.revoquerToken(hacher(tokenBrut));
        }
    }

    /** Révoque tous les tokens d'un utilisateur (changement MDP, suspension). */
    @Transactional
    public int revoquerTous(UUID utilisateurId) {
        int n = repository.revoquerTousLesTokens(utilisateurId);
        log.info("[REFRESH] {} tokens révoqués pour utilisateur {}", n, utilisateurId);
        return n;
    }

    /** SHA-256 d'un token en Base64 URL-safe. */
    public String hacher(String token) {
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256")
                .digest(token.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(hash);
        } catch (Exception e) {
            throw new RuntimeException("Erreur hachage token", e);
        }
    }
}
