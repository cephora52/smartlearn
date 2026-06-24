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
