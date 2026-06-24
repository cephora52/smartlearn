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
