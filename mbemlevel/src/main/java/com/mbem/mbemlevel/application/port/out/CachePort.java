// =============================================================================
// MbemNova — application/port/out/CachePort.java
// Port sortant pour le cache Redis avec TTL.
// =============================================================================
package com.mbem.mbemlevel.application.port.out;

import java.time.Duration;
import java.util.Optional;

/**
 * Port sortant — cache Redis.
 * Implémenté par RedisCacheAdapter (infrastructure).
 *
 * <p>Usage type : progression d'un cours (TTL 5min), catalogue (TTL 10min),
 * places disponibles d'une session (TTL 30s), blacklist JWT (TTL = restant du token).</p>
 */
public interface CachePort {

    /** Met une valeur en cache avec TTL. */
    void set(String cle, String valeur, Duration ttl);

    /** Récupère une valeur. Retourne empty si absente ou expirée. */
    Optional<String> get(String cle);

    /** Supprime une clé du cache. */
    void evict(String cle);

    /** Vérifie l'existence d'une clé (plus léger que get). */
    boolean exists(String cle);

    /** Incrémente un compteur atomiquement (rate limiting). */
    long increment(String cle, Duration ttl);
}
