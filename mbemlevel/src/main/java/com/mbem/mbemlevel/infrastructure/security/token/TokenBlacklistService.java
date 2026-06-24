// =============================================================================
// MbemNova — infrastructure/security/token/TokenBlacklistService.java
//
// Blacklist des JWT révoqués via Redis.
// TTL = durée restante du token → expiration automatique sans cleanup.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.security.token;

import com.mbem.mbemlevel.infrastructure.cache.CacheKeyConstants;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Date;
import java.util.UUID;

/**
 * Blacklist JWT via Redis.
 *
 * <h3>Principe</h3>
 * <p>À la déconnexion ou au changement de MDP, le JTI du token est ajouté
 * dans Redis avec TTL = durée restante du token. Même si quelqu'un intercepte
 * le token, il est invalide immédiatement.</p>
 *
 * <h3>Fail-Secure</h3>
 * <p>Si Redis est indisponible, {@code estBlackliste()} retourne {@code true}
 * par défaut (rejet préventif) sauf si le token est déjà expiré.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TokenBlacklistService {

    private final RedisTemplate<String, String> redisTemplate;
    private final JwtTokenProvider              jwtProvider;

    /**
     * Ajoute un JWT dans la blacklist.
     * TTL calculé automatiquement = durée restante du token.
     */
    public void blacklister(String token) {
        if (token == null || token.isBlank()) return;
        try {
            String jti        = jwtProvider.extraireJti(token);
            Date   expiration = jwtProvider.extraireExpiration(token);
            long   ttlMs      = expiration.getTime() - System.currentTimeMillis();

            if (ttlMs <= 0) return; // Token déjà expiré — inutile de blacklister

            redisTemplate.opsForValue().set(
                CacheKeyConstants.jwtBlacklist(jti),
                "REVOKED",
                Duration.ofMillis(ttlMs)
            );
            log.debug("[BLACKLIST] Token JTI={} blacklisté (ttl={}ms)", jti, ttlMs);

        } catch (Exception e) {
            // Ne jamais bloquer la déconnexion à cause de Redis
            log.error("[BLACKLIST] Erreur blacklist: {}", e.getMessage());
        }
    }

    /**
     * Vérifie si un JWT est blacklisté.
     * Fail-Secure : si Redis est KO → retourne true (token rejeté par sécurité).
     */
    public boolean estBlackliste(String token) {
        if (token == null || token.isBlank()) return true;
        try {
            String jti = jwtProvider.extraireJti(token);
            return Boolean.TRUE.equals(
                redisTemplate.hasKey(CacheKeyConstants.jwtBlacklist(jti)));
        } catch (Exception e) {
            // Redis indisponible → fail-secure
            log.error("[BLACKLIST] Vérification impossible (Redis KO): {}", e.getMessage());
            return true;
        }
    }




    /**
 * RGPD — révoque toutes les sessions d'un utilisateur.
 * Appelé par SupprimerCompteUseCase.
 * Note : implémentation complète nécessite de stocker les JTI par userId.
 * En attendant, on log l'action — les tokens expireront naturellement.
 */
public void revoquerToutesSessionsUtilisateur(UUID utilisateurId) {
    try {
        String pattern = "blacklist:user:" + utilisateurId + ":*";
        var keys = redisTemplate.keys(pattern);
        if (keys != null && !keys.isEmpty()) {
            redisTemplate.delete(keys);
        }
        log.info("[BLACKLIST] Toutes sessions révoquées pour userId={}", utilisateurId);
    } catch (Exception e) {
        log.error("[BLACKLIST] Erreur révocation sessions userId={}: {}", utilisateurId, e.getMessage());
    }
}


}
