// =============================================================================
// MbemNova — infrastructure/config/JpaConfig.java
// Configuration JPA : auditing automatique @CreatedDate / @LastModifiedDate.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.auditing.DateTimeProvider;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.concurrent.Executor;

/**
 * Configuration JPA + async.
 *
 * <p>{@code @EnableJpaAuditing} active les annotations
 * {@code @CreatedDate} et {@code @LastModifiedDate} sur les entités JPA.
 * La {@code dateTimeProviderRef} garantit l'utilisation de
 * {@code LocalDateTime} cohérent avec la timezone Africa/Douala.</p>
 *
 * <p>{@code @EnableAsync} active les handlers d'events asynchrones
 * ({@code @EventListener @Async}).</p>
 */
@Configuration
@EnableJpaAuditing(dateTimeProviderRef = "auditingDateTimeProvider")
@EnableAsync
public class JpaConfig {

    /**
     * Fournisseur de date/heure pour le JPA Auditing.
     * Retourne LocalDateTime.now() (timezone configurée dans application.yaml).
     */
    @Bean(name = "auditingDateTimeProvider")
    public DateTimeProvider dateTimeProvider() {
        return () -> Optional.of(LocalDateTime.now());
    }

    /**
     * Thread pool pour les handlers d'events asynchrones (@Async).
     * Dimensionné pour ne pas saturer le pool Tomcat.
     */
    @Bean(name = "asyncEventExecutor")
    public Executor asyncEventExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(5);
        executor.setQueueCapacity(50);
        executor.setThreadNamePrefix("mbem-async-");
        executor.initialize();
        return executor;
    }
}
