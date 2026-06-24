package com.mbem.mbemlevel.infrastructure.config;

import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.timelimiter.TimeLimiterConfig;
import org.springframework.cloud.circuitbreaker.resilience4j.Resilience4JCircuitBreakerFactory;
import org.springframework.cloud.circuitbreaker.resilience4j.Resilience4JConfigBuilder;
import org.springframework.cloud.client.circuitbreaker.Customizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import java.time.Duration;

/**
 * Configuration des circuit breakers pour les services externes.
 *
 * Protège MbemNova si :
 *   - L'API WhatsApp Business Meta est lente ou tombe → circuit ouvert, retry en queue
 *   - Le serveur SMTP Brevo est surchargé → circuit ouvert, email en retry
 *   - MinIO est temporairement indisponible → circuit ouvert, upload en retry
 *
 * Pattern circuit breaker :
 *   FERMÉ (normal) → OUVERT (>50% erreurs) → DEMI-OUVERT (teste) → FERMÉ
 */
@Configuration
public class ResilienceConfig {

    @Bean
    public Customizer<Resilience4JCircuitBreakerFactory> circuitBreakerConfig() {
        return factory -> {

            // WhatsApp Business API — peut être lente (3-5s)
            factory.configure(builder -> whatsAppBreaker(builder), "whatsapp");

            // Email SMTP — généralement rapide mais peut saturer
            factory.configure(builder -> emailBreaker(builder), "email");

            // MinIO Storage — réseau interne mais peut avoir des pics
            factory.configure(builder -> storageBreaker(builder), "storage");
        };
    }

    private Resilience4JConfigBuilder whatsAppBreaker(Resilience4JConfigBuilder builder) {
        return builder
            .timeLimiterConfig(TimeLimiterConfig.custom()
                .timeoutDuration(Duration.ofSeconds(5))  // 5s max pour WhatsApp
                .build())
            .circuitBreakerConfig(CircuitBreakerConfig.custom()
                .failureRateThreshold(50)           // Ouvre si 50% d'échecs
                .waitDurationInOpenState(Duration.ofSeconds(30))
                .slidingWindowSize(10)              // Sur les 10 derniers appels
                .minimumNumberOfCalls(5)
                .build());
    }

    private Resilience4JConfigBuilder emailBreaker(Resilience4JConfigBuilder builder) {
        return builder
            .timeLimiterConfig(TimeLimiterConfig.custom()
                .timeoutDuration(Duration.ofSeconds(10)) // SMTP peut être lent
                .build())
            .circuitBreakerConfig(CircuitBreakerConfig.custom()
                .failureRateThreshold(40)
                .waitDurationInOpenState(Duration.ofMinutes(1))
                .slidingWindowSize(20)
                .minimumNumberOfCalls(10)
                .build());
    }

    private Resilience4JConfigBuilder storageBreaker(Resilience4JConfigBuilder builder) {
        return builder
            .timeLimiterConfig(TimeLimiterConfig.custom()
                .timeoutDuration(Duration.ofSeconds(15)) // Upload peut prendre du temps
                .build())
            .circuitBreakerConfig(CircuitBreakerConfig.custom()
                .failureRateThreshold(30)
                .waitDurationInOpenState(Duration.ofSeconds(20))
                .slidingWindowSize(10)
                .minimumNumberOfCalls(5)
                .build());
    }
}
