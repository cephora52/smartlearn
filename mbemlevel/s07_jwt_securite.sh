#!/usr/bin/env bash
# =============================================================================
# MbemNova — Script 07/15 : Infrastructure Sécurité JWT
# =============================================================================
# RÔLE   : Implémente toute la couche sécurité JWT de l'infrastructure.
#
# CONTENU :
#   ── JWT + Tokens (infrastructure/security/token/) ────────────────────────
#   JwtTokenProvider.java      — Génération/validation JWT Nimbus JOSE HS256
#   TokenBlacklistService.java — Blacklist JWT via Redis (TTL = restant token)
#   RefreshTokenService.java   — Rotation sécurisée refresh tokens
#   ResetPasswordTokenService.java — Reset MDP : tokens usage unique TTL 1h
#   JwtFacadeImpl.java         — Implémentation de l'interface JwtFacade
#
#   ── Cache Redis (infrastructure/cache/) ──────────────────────────────────
#   CacheKeyConstants.java     — Constantes clés Redis centralisées
#   RedisCacheAdapter.java     — Implémente CachePort
#   RedisConfig.java           — Configuration RedisTemplate + sérialization JSON
#
#   ── Audit (infrastructure/audit/) ────────────────────────────────────────
#   AuditLogService.java       — Façade de logging audit (accessible aux use cases)
#
#   ── Scheduler tokens (infrastructure/scheduler/) ─────────────────────────
#   CleanupTokenScheduler.java — Nettoyage nocturne refresh + reset tokens
#
# PRÉREQUIS : s01 à s06 doivent avoir été lancés
# USAGE     : chmod +x s07_jwt_securite.sh && ./s07_jwt_securite.sh
# =============================================================================

set -euo pipefail
export LC_ALL=C.UTF-8

C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_CYAN='\033[0;36m'
C_BOLD='\033[1m';     C_NC='\033[0m'

log_ok()  { echo -e "${C_GREEN}  [OK]${C_NC} $1"; }
log_sec() { echo -e "\n${C_BOLD}${C_CYAN}── $1 ──${C_NC}"; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$ROOT/src/main/java/com/mbem/mbemlevel"

echo ""
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo -e "${C_BOLD}${C_CYAN}  MbemNova · Script 07/15 · Sécurité JWT       ${C_NC}"
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo ""

[[ ! -f "$ROOT/pom.xml" ]] && { echo "ERREUR: lancez s01 d'abord"; exit 1; }
[[ ! -d "$PKG/infrastructure/persistence" ]] && { echo "ERREUR: lancez s06 d'abord"; exit 1; }

# =============================================================================
# SECTION 1 — CONSTANTES CACHE REDIS
# =============================================================================
log_sec "1/6 Constantes cache Redis"
mkdir -p "$PKG/infrastructure/cache"

cat > "$PKG/infrastructure/cache/CacheKeyConstants.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/cache/CacheKeyConstants.java
// Constantes de toutes les clés Redis centralisées en un seul endroit.
// Convention : mbemnova:{domaine}:{identifiant}
// =============================================================================
package com.mbem.mbemlevel.infrastructure.cache;

/**
 * Constantes des clés Redis MbemNova.
 * Centraliser ici évite les fautes de frappe et facilite le monitoring.
 *
 * <h3>TTL par catégorie</h3>
 * <ul>
 *   <li>JWT blacklist : TTL = durée restante du token (auto-expiration)</li>
 *   <li>Rate limiting : TTL = fenêtre configurée (60s, 3600s…)</li>
 *   <li>Catalogue cours : 10 minutes (peu de changements)</li>
 *   <li>Progression : 5 minutes (mise à jour fréquente)</li>
 *   <li>Places session : 30 secondes (données très volatiles)</li>
 * </ul>
 */
public final class CacheKeyConstants {

    private CacheKeyConstants() { /* Classe utilitaire */ }

    private static final String APP = "mbemnova";

    // ── JWT Blacklist ─────────────────────────────────────────────────────────
    /** mbemnova:jwt:blacklist:{jti} — utilisé par TokenBlacklistService */
    public static String jwtBlacklist(String jti) {
        return APP + ":jwt:blacklist:" + jti;
    }

    // ── Rate Limiting ─────────────────────────────────────────────────────────
    /** mbemnova:rl:{endpoint}:{ip} — compteur Bucket4j */
    public static String rateLimitKey(String endpoint, String ip) {
        return APP + ":rl:" + endpoint + ":" + ip;
    }

    // ── Catalogue Cours ───────────────────────────────────────────────────────
    /** mbemnova:cours:catalogue:{hashFiltres} — cache 10 min */
    public static String catalogueCours(String hashFiltres) {
        return APP + ":cours:catalogue:" + hashFiltres;
    }

    /** mbemnova:cours:{coursId} — détail d'un cours */
    public static String detailCours(String coursId) {
        return APP + ":cours:" + coursId;
    }

    // ── Progression ───────────────────────────────────────────────────────────
    /** mbemnova:progression:{userId}:{coursId} — cache 5 min */
    public static String progression(String userId, String coursId) {
        return APP + ":progression:" + userId + ":" + coursId;
    }

    // ── Session ───────────────────────────────────────────────────────────────
    /** mbemnova:session:places:{sessionId} — places disponibles cache 30s */
    public static String placesSession(String sessionId) {
        return APP + ":session:places:" + sessionId;
    }

    // ── Utilisateur ───────────────────────────────────────────────────────────
    /** mbemnova:user:{userId} — profil cache 5 min */
    public static String utilisateur(String userId) {
        return APP + ":user:" + userId;
    }

    // ── Statistiques Admin ────────────────────────────────────────────────────
    /** mbemnova:admin:stats — tableau de bord admin cache 1 min */
    public static String statsAdmin() {
        return APP + ":admin:stats";
    }
}
JEOF
log_ok "CacheKeyConstants.java"

# =============================================================================
# SECTION 2 — CONFIGURATION REDIS
# =============================================================================
log_sec "2/6 Configuration Redis"

cat > "$PKG/infrastructure/cache/RedisConfig.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/cache/RedisConfig.java
// Configuration RedisTemplate avec sérialisation JSON (Jackson).
// =============================================================================
package com.mbem.mbemlevel.infrastructure.cache;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import java.time.Duration;

/**
 * Configuration Redis pour MbemNova.
 *
 * <h3>Sérialisation</h3>
 * <p>Clés : {@code String} (lisibles en Redis CLI).
 * Valeurs : {@code JSON} via Jackson (pas de sérialisation Java binaire).</p>
 *
 * <h3>TTL par défaut : 10 minutes</h3>
 * <p>Peut être surchargé par clé dans les services.</p>
 */
@Configuration
@EnableCaching
public class RedisConfig {

    /**
     * ObjectMapper partagé pour Redis — support LocalDateTime ISO-8601.
     */
    @Bean(name = "redisObjectMapper")
    public ObjectMapper redisObjectMapper() {
        return new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    }

    /**
     * Template Redis typé String → String.
     * Utilisé par TokenBlacklistService, CacheKeyConstants etc.
     */
    @Bean
    public RedisTemplate<String, String> redisTemplate(RedisConnectionFactory cf) {
        RedisTemplate<String, String> template = new RedisTemplate<>();
        template.setConnectionFactory(cf);
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(new StringRedisSerializer());
        template.setHashKeySerializer(new StringRedisSerializer());
        template.setHashValueSerializer(new StringRedisSerializer());
        template.afterPropertiesSet();
        return template;
    }

    /**
     * Cache Manager Spring (@Cacheable @CacheEvict).
     * TTL par défaut : 10 min.
     */
    @Bean
    public RedisCacheManager cacheManager(RedisConnectionFactory cf,
                                          ObjectMapper redisObjectMapper) {
        GenericJackson2JsonRedisSerializer serializer =
            new GenericJackson2JsonRedisSerializer(redisObjectMapper);

        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(10))
            .serializeKeysWith(
                RedisSerializationContext.SerializationPair.fromSerializer(
                    new StringRedisSerializer()))
            .serializeValuesWith(
                RedisSerializationContext.SerializationPair.fromSerializer(serializer))
            .disableCachingNullValues();

        return RedisCacheManager.builder(cf).cacheDefaults(config).build();
    }
}
JEOF
log_ok "RedisConfig.java"

cat > "$PKG/infrastructure/cache/RedisCacheAdapter.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/cache/RedisCacheAdapter.java
// Implémente CachePort via RedisTemplate.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.cache;

import com.mbem.mbemlevel.application.port.out.CachePort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Optional;

/**
 * Adaptateur cache Redis.
 * Toutes les opérations sont fail-safe : en cas d'indisponibilité Redis,
 * retourne des valeurs vides plutôt que de faire échouer le métier.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class RedisCacheAdapter implements CachePort {

    private final RedisTemplate<String, String> redisTemplate;

    @Override
    public void set(String cle, String valeur, Duration ttl) {
        try {
            redisTemplate.opsForValue().set(cle, valeur, ttl);
        } catch (Exception e) {
            log.warn("[CACHE] set failed key={}: {}", cle, e.getMessage());
        }
    }

    @Override
    public Optional<String> get(String cle) {
        try {
            String val = redisTemplate.opsForValue().get(cle);
            return Optional.ofNullable(val);
        } catch (Exception e) {
            log.warn("[CACHE] get failed key={}: {}", cle, e.getMessage());
            return Optional.empty();
        }
    }

    @Override
    public void evict(String cle) {
        try {
            redisTemplate.delete(cle);
        } catch (Exception e) {
            log.warn("[CACHE] evict failed key={}: {}", cle, e.getMessage());
        }
    }

    @Override
    public boolean exists(String cle) {
        try {
            return Boolean.TRUE.equals(redisTemplate.hasKey(cle));
        } catch (Exception e) {
            log.warn("[CACHE] exists failed key={}: {}", cle, e.getMessage());
            return false;
        }
    }

    @Override
    public long increment(String cle, Duration ttl) {
        try {
            Long val = redisTemplate.opsForValue().increment(cle);
            if (val != null && val == 1L) {
                // Premier incrément → définir le TTL
                redisTemplate.expire(cle, ttl);
            }
            return val != null ? val : 0L;
        } catch (Exception e) {
            log.warn("[CACHE] increment failed key={}: {}", cle, e.getMessage());
            return 0L;
        }
    }
}
JEOF
log_ok "RedisCacheAdapter.java"

# =============================================================================
# SECTION 3 — JWT TOKEN PROVIDER (Nimbus JOSE HS256)
# =============================================================================
log_sec "3/6 JwtTokenProvider (Nimbus JOSE)"
mkdir -p "$PKG/infrastructure/security/token"

cat > "$PKG/infrastructure/security/token/JwtTokenProvider.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/security/token/JwtTokenProvider.java
//
// Génération et validation de JWT avec Nimbus JOSE JWT (HS256).
// Le secret vient EXCLUSIVEMENT de la variable d'environnement JWT_SECRET.
//
// STRUCTURE DU JWT GÉNÉRÉ :
//   Header  : {"alg":"HS256","typ":"JWT"}
//   Payload : {
//     "sub"   : "uuid-utilisateur",
//     "email" : "user@mbemnova.com",
//     "role"  : "APPRENANT",
//     "jti"   : "uuid-unique-par-token",   ← pour la blacklist
//     "iss"   : "mbemnova.com",
//     "iat"   : timestamp,
//     "exp"   : timestamp
//   }
//
// SÉCURITÉ :
//   - Secret minimum 32 chars (256 bits) — validé au démarrage
//   - JTI unique par token → permet la blacklist individuelle à la déconnexion
//   - Expiration vérifiée à chaque requête par JwtAuthenticationFilter
// =============================================================================
package com.mbem.mbemlevel.infrastructure.security.token;

import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.*;
import com.nimbusds.jwt.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;
import java.util.UUID;

/**
 * Fournisseur JWT utilisant Nimbus JOSE (inclus via spring-security-oauth2-resource-server).
 * Un seul bean partagé — thread-safe (SecretKey est immuable).
 */
@Component
@Slf4j
public class JwtTokenProvider {

    private final SecretKey secretKey;
    private final long      expirationMs;

    public JwtTokenProvider(
        @Value("${security.jwt.secret}") String secret,
        @Value("${security.jwt.expiration-ms:86400000}") long expirationMs
    ) {
        if (secret == null || secret.length() < 32) {
            throw new IllegalStateException(
                "JWT_SECRET trop court ! Minimum 32 caractères requis. Actuel: "
                + (secret != null ? secret.length() : 0) + " chars.");
        }
        try {
            // Dériver 256 bits depuis le secret via SHA-256 (clé uniforme)
            byte[] keyBytes = MessageDigest.getInstance("SHA-256")
                .digest(secret.getBytes(StandardCharsets.UTF_8));
            this.secretKey   = new SecretKeySpec(keyBytes, "HmacSHA256");
            this.expirationMs = expirationMs;
            log.info("[JWT] Provider initialisé (exp={}ms, alg=HS256)", expirationMs);
        } catch (Exception e) {
            throw new IllegalStateException("Impossible d'initialiser la clé JWT", e);
        }
    }

    /**
     * Génère un JWT signé HS256.
     *
     * @param userId UUID de l'utilisateur (subject)
     * @param email  Email (claim custom — évite les requêtes BDD dans le filtre)
     * @param role   Rôle (claim custom — RBAC sans requête BDD)
     * @return JWT compact signé
     */
    public String genererToken(String userId, String email, String role) {
        Instant now        = Instant.now();
        Instant expiration = now.plus(expirationMs, ChronoUnit.MILLIS);

        JWTClaimsSet claims = new JWTClaimsSet.Builder()
            .subject(userId)
            .claim("email", email)
            .claim("role",  role)
            .jwtID(UUID.randomUUID().toString())  // JTI unique pour la blacklist
            .issuer("mbemnova.com")
            .issueTime(Date.from(now))
            .expirationTime(Date.from(expiration))
            .build();

        try {
            SignedJWT jwt = new SignedJWT(new JWSHeader(JWSAlgorithm.HS256), claims);
            jwt.sign(new MACSigner(secretKey));
            return jwt.serialize();
        } catch (JOSEException e) {
            throw new RuntimeException("Erreur génération JWT", e);
        }
    }

    /**
     * Valide un JWT et retourne ses claims.
     *
     * @param token JWT compact
     * @return Claims validés
     * @throws SecurityException si signature invalide ou token expiré
     */
    public JWTClaimsSet validerEtExtraireClaims(String token) {
        try {
            SignedJWT jwt = SignedJWT.parse(token);

            if (!jwt.verify(new MACVerifier(secretKey))) {
                throw new SecurityException("Signature JWT invalide");
            }

            JWTClaimsSet claims = jwt.getJWTClaimsSet();
            if (claims.getExpirationTime().before(new Date())) {
                throw new SecurityException("JWT expiré");
            }
            return claims;

        } catch (SecurityException e) {
            throw e;
        } catch (Exception e) {
            throw new SecurityException("JWT invalide : " + e.getMessage());
        }
    }

    /** Extrait le JTI (JWT ID) sans valider — pour la blacklist. */
    public String extraireJti(String token) {
        try {
            return SignedJWT.parse(token).getJWTClaimsSet().getJWTID();
        } catch (Exception e) {
            throw new SecurityException("JTI introuvable dans le JWT");
        }
    }

    /** Extrait la date d'expiration sans valider. */
    public Date extraireExpiration(String token) {
        try {
            return SignedJWT.parse(token).getJWTClaimsSet().getExpirationTime();
        } catch (Exception e) {
            throw new SecurityException("Expiration introuvable dans le JWT");
        }
    }

    /** @return true si le JWT est syntaxiquement valide ET non expiré. */
    public boolean estValide(String token) {
        try {
            validerEtExtraireClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
JEOF
log_ok "JwtTokenProvider.java"

# =============================================================================
# SECTION 4 — SERVICES TOKENS (Blacklist, Refresh, Reset)
# =============================================================================
log_sec "4/6 Services tokens (blacklist, refresh, reset)"

cat > "$PKG/infrastructure/security/token/TokenBlacklistService.java" << 'JEOF'
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
}
JEOF
log_ok "TokenBlacklistService.java"

cat > "$PKG/infrastructure/security/token/RefreshTokenService.java" << 'JEOF'
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
JEOF
log_ok "RefreshTokenService.java"

cat > "$PKG/infrastructure/security/token/ResetPasswordTokenService.java" << 'JEOF'
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
JEOF
log_ok "ResetPasswordTokenService.java"

# =============================================================================
# SECTION 5 — JWT FACADE IMPLEMENTATION
# =============================================================================
log_sec "5/6 JwtFacadeImpl"

cat > "$PKG/infrastructure/security/token/JwtFacadeImpl.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/security/token/JwtFacadeImpl.java
//
// Implémentation de l'interface JwtFacade définie dans la couche Application.
// Cette classe "colle" les services JWT de l'infrastructure à l'interface
// attendue par les use cases — principe d'inversion de dépendance.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.security.token;

import com.mbem.mbemlevel.application.usecase.auth.JwtFacade;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

/**
 * Implémentation de {@link JwtFacade} — expose les services tokens
 * de l'infrastructure à la couche Application sans couplage direct.
 */
@Component
@RequiredArgsConstructor
public class JwtFacadeImpl implements JwtFacade {

    private final JwtTokenProvider          jwtProvider;
    private final TokenBlacklistService     blacklistService;
    private final RefreshTokenService       refreshTokenService;
    private final ResetPasswordTokenService resetTokenService;

    // ── Access Token ─────────────────────────────────────────────────────────

    @Override
    public String genererToken(String userId, String email, String role) {
        return jwtProvider.genererToken(userId, email, role);
    }

    @Override
    public void blacklister(String accessToken) {
        blacklistService.blacklister(accessToken);
    }

    // ── Refresh Token ─────────────────────────────────────────────────────────

    @Override
    public String genererRefreshToken(UUID utilisateurId, int ttlJours,
                                      String ip, String userAgent) {
        return refreshTokenService.generer(utilisateurId, ttlJours, ip, userAgent);
    }

    @Override
    public Optional<UUID> validerRefreshTokenEtRoter(String refreshTokenBrut) {
        return refreshTokenService.validerEtRoter(refreshTokenBrut);
    }

    @Override
    public void revoquerRefreshToken(String refreshTokenBrut) {
        refreshTokenService.revoquer(refreshTokenBrut);
    }

    @Override
    public void revoquerTousRefreshTokens(UUID utilisateurId) {
        refreshTokenService.revoquerTous(utilisateurId);
    }

    // ── Reset Token ───────────────────────────────────────────────────────────

    @Override
    public String genererResetToken(UUID utilisateurId, int ttlMinutes, String ip) {
        return resetTokenService.generer(utilisateurId, ttlMinutes, ip);
    }

    @Override
    public String hacherTokenReset(String tokenBrut) {
        return resetTokenService.hacher(tokenBrut);
    }
}
JEOF
log_ok "JwtFacadeImpl.java"

# =============================================================================
# SECTION 6 — AUDIT SERVICE + SCHEDULER NETTOYAGE
# =============================================================================
log_sec "6/6 AuditLogService + CleanupTokenScheduler"
mkdir -p "$PKG/infrastructure/audit"
mkdir -p "$PKG/infrastructure/scheduler"

cat > "$PKG/infrastructure/audit/AuditLogService.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/audit/AuditLogService.java
//
// Service d'audit centralisé — façade sur AuditLogRepository.
// Simplifie les appels depuis les use cases et les aspects AOP.
// Extrait automatiquement l'IP depuis la requête HTTP courante.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.audit;

import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Map;
import java.util.UUID;

/**
 * Service d'audit centralisé pour MbemNova.
 *
 * <h3>Usage dans les use cases</h3>
 * <pre>{@code
 * // Action réussie
 * auditService.succes(userId, email, "LOGIN_SUCCESS", "UTILISATEUR", userId.toString(), null);
 *
 * // Échec
 * auditService.echec(null, email, "LOGIN_FAILURE", "UTILISATEUR", null,
 *     Map.of("raison", "Email inexistant"));
 * }</pre>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AuditLogService {

    private final AuditLogRepository repository;

    /** Journalise une action réussie. */
    public void succes(UUID userId, String email, String action,
                       String ressourceType, String ressourceId,
                       Map<String, Object> details) {
        enregistrer(userId, email, action, ressourceType, ressourceId, details, "SUCCESS");
    }

    /** Journalise un échec. */
    public void echec(UUID userId, String email, String action,
                      String ressourceType, String ressourceId,
                      Map<String, Object> details) {
        enregistrer(userId, email, action, ressourceType, ressourceId, details, "FAILURE");
    }

    /** Journalise un avertissement. */
    public void avertissement(UUID userId, String email, String action,
                               String ressourceType, String ressourceId,
                               Map<String, Object> details) {
        enregistrer(userId, email, action, ressourceType, ressourceId, details, "WARNING");
    }

    private void enregistrer(UUID userId, String email, String action,
                              String ressourceType, String ressourceId,
                              Map<String, Object> details, String statut) {
        String ip        = null;
        String userAgent = null;

        // Récupérer IP et User-Agent depuis la requête HTTP courante (si disponible)
        try {
            ServletRequestAttributes attrs =
                (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attrs != null) {
                HttpServletRequest req = attrs.getRequest();
                ip        = extraireIpReelle(req);
                userAgent = req.getHeader("User-Agent");
            }
        } catch (Exception ignored) {
            // Hors contexte HTTP (scheduler, test) — IP null
        }

        repository.enregistrer(userId, email, action, ressourceType,
            ressourceId, details, statut, ip, userAgent);
    }

    /**
     * Extrait l'IP réelle en tenant compte du reverse proxy Nginx.
     * Nginx ajoute X-Forwarded-For avec l'IP originale du client.
     */
    private String extraireIpReelle(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            // Format : "ip-client, ip-proxy1, ip-proxy2" → prendre la première
            return forwarded.split(",")[0].trim();
        }
        String realIp = request.getHeader("X-Real-IP");
        if (realIp != null && !realIp.isBlank()) {
            return realIp.trim();
        }
        return request.getRemoteAddr();
    }
}
JEOF
log_ok "AuditLogService.java"

cat > "$PKG/infrastructure/scheduler/CleanupTokenScheduler.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/scheduler/CleanupTokenScheduler.java
//
// Nettoyage nocturne des tokens expirés et révoqués.
// Évite l'accumulation en base de données.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.scheduler;

import com.mbem.mbemlevel.application.port.out.RefreshTokenRepository;
import com.mbem.mbemlevel.application.port.out.ResetTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Scheduler de nettoyage des tokens expirés.
 *
 * <h3>Fréquence</h3>
 * <p>Chaque nuit à 02h00 (timezone Africa/Douala) — quand le trafic est minimal.</p>
 *
 * <h3>Ce que ça supprime</h3>
 * <ul>
 *   <li>Refresh tokens expirés OU révoqués</li>
 *   <li>Reset tokens expirés OU déjà utilisés</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class CleanupTokenScheduler {

    private final RefreshTokenRepository refreshTokenRepo;
    private final ResetTokenRepository   resetTokenRepo;

    /**
     * Nettoyage quotidien à 02:00 (Africa/Douala = UTC+1).
     * Cron : "0 0 2 * * ?" = chaque jour à 02:00:00.
     * La timezone est configurée dans application.yaml (SchedulerConfig).
     */
    @Scheduled(cron = "0 0 2 * * ?", zone = "Africa/Douala")
    public void nettoyerTokensExpires() {
        log.info("[CLEANUP] Démarrage nettoyage tokens expirés");

        try {
            int refreshSupprimes = refreshTokenRepo.nettoyerTokensExpires();
            int resetSupprimes   = resetTokenRepo.nettoyerTokensExpires();

            log.info("[CLEANUP] Terminé: {} refresh tokens + {} reset tokens supprimés",
                refreshSupprimes, resetSupprimes);
        } catch (Exception e) {
            log.error("[CLEANUP] Erreur nettoyage tokens: {}", e.getMessage(), e);
        }
    }
}
JEOF
log_ok "CleanupTokenScheduler.java"

# Créer SchedulerConfig manquant
mkdir -p "$PKG/infrastructure/config"
cat > "$PKG/infrastructure/config/SchedulerConfig.java" << 'JEOF'
// MbemNova — infrastructure/config/SchedulerConfig.java
package com.mbem.mbemlevel.infrastructure.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Active les @Scheduled.
 * La timezone par défaut est Africa/Douala (configurée dans application.yaml).
 */
@Configuration
@EnableScheduling
public class SchedulerConfig {
    // @Scheduled dans les schedulers utilisent zone="Africa/Douala" directement
}
JEOF
log_ok "SchedulerConfig.java"

# =============================================================================
# RÉSUMÉ
# =============================================================================
echo ""
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo -e "${C_BOLD}${C_GREEN}  Script 07/15 terminé avec succès              ${C_NC}"
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo ""
echo -e "  ${C_GREEN}✓${C_NC}  CacheKeyConstants + RedisConfig + RedisCacheAdapter"
echo -e "  ${C_GREEN}✓${C_NC}  JwtTokenProvider (Nimbus JOSE HS256, JTI pour blacklist)"
echo -e "  ${C_GREEN}✓${C_NC}  TokenBlacklistService (Redis, fail-secure)"
echo -e "  ${C_GREEN}✓${C_NC}  RefreshTokenService (rotation sécurisée SHA-256)"
echo -e "  ${C_GREEN}✓${C_NC}  ResetPasswordTokenService (usage unique TTL 1h)"
echo -e "  ${C_GREEN}✓${C_NC}  JwtFacadeImpl (bridge Application ↔ Infrastructure)"
echo -e "  ${C_GREEN}✓${C_NC}  AuditLogService (extraction IP X-Forwarded-For)"
echo -e "  ${C_GREEN}✓${C_NC}  CleanupTokenScheduler (nettoyage nocturne 02h00)"
echo -e "  ${C_GREEN}✓${C_NC}  SchedulerConfig"
echo ""
echo -e "  \033[1;33m→ Prochain script : ./s08_api_security.sh${C_NC}"
echo ""
