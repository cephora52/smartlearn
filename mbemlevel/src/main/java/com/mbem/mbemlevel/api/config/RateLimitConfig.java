package com.mbem.mbemlevel.api.config;
import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
/**
 * Rate limiting Bucket4j par IP.
 * Limites configurées dans application.yaml (mbemnova.rate-limit.*).
 */
@Component
@RequiredArgsConstructor
public class RateLimitConfig {
    // Cache local des buckets par clé (IP+endpoint)
    private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

    /** Retourne ou crée un bucket pour une clé donnée. */
    public Bucket resolveBucket(String key, int capacity, Duration refillDuration) {
        return buckets.computeIfAbsent(key, k ->
            Bucket.builder()
                .addLimit(Bandwidth.builder()
                    .capacity(capacity)
                    .refillGreedy(capacity, refillDuration)
                    .build())
                .build());
    }
}
