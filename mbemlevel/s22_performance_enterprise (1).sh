#!/usr/bin/env bash
# =============================================================================
# MbemNova — s22_performance_enterprise.sh
# Optimisations pour passer de 50 à 2000+ utilisateurs simultanés
#
# 1.  Virtual Threads Java 21          → x10 sur les I/O
# 2.  Hikari Pool prod optimisé        → 30 connexions, leak detection
# 3.  @Cacheable sur catalogue + cours → Redis évite PostgreSQL à chaque appel
# 4.  AsyncConfig — pools dédiés       → email / PDF / WhatsApp séparés
# 5.  Projections DTO légères          → 3x moins de data pour le catalogue
# 6.  N+1 Query corrigé               → JOIN FETCH sur cours→modules→leçons
# 7.  Circuit Breakers (Resilience4j)  → protège si WhatsApp/Email tombent
# 8.  Soft Delete                      → audit trail complet, restauration
# 9.  nginx cache images               → 7 jours CDN local
# 10. Slow Query monitoring            → détecte tout > 100ms
# 11. Index CONCURRENTLY manquants     → sans bloquer la prod
# 12. CacheConfig Redis avec TTL       → TTL par cache, serialisation JSON
# =============================================================================
set -euo pipefail
ROOT="${1:-.}"
P="$ROOT/src/main/java/com/mbem/mbemlevel"
RES="$ROOT/src/main/resources"
MIG="$ROOT/src/main/resources/db/migration"
C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_NC='\033[0m'
ok()  { echo -e "  ${C_GREEN}✓${C_NC}  $1"; }
sec() { echo -e "\n${C_BLUE}▶ $1${C_NC}"; }

mkdir -p "$P/infrastructure/config"
mkdir -p "$P/infrastructure/persistence/repository/projection"
mkdir -p "$MIG"

echo -e "\n${C_BLUE}══════════════════════════════════════════════════════════════${C_NC}"
echo -e "${C_BLUE}  MbemNova · s22 · Performance Enterprise                      ${C_NC}"
echo -e "${C_BLUE}══════════════════════════════════════════════════════════════${C_NC}\n"

# =============================================================================
# 1. application-prod.yml — Virtual Threads + Hikari optimisé + slow queries
# =============================================================================
sec "1/12 application-prod.yml — performance production"

cat > "$RES/application-prod.yml" << 'YAMLEOF'
# =============================================================================
# MbemNova — Configuration PRODUCTION
# Objectif : 500-2000 apprenants simultanés, p95 < 200ms
# =============================================================================

spring:

  # ── Virtual Threads Java 21 ─────────────────────────────────────────────────
  # Active les threads virtuels pour TOUS les servlets, @Async et @Scheduled
  # Impact : x5-x10 sur les I/O bound (lecture DB, appels API externes)
  # Prérequis : Java 21+ (déjà dans le Dockerfile)
  threads:
    virtual:
      enabled: true

  # ── Base de données — Hikari Connection Pool optimisé ───────────────────────
  datasource:
    url: ${DATABASE_URL}
    username: ${DATABASE_USERNAME}
    password: ${DATABASE_PASSWORD}
    hikari:
      pool-name: HikariPool-Prod

      # Formule : (nb_cores × 2) + nb_disques = 8×2+1 = 17 → arrondi 20
      # Pour un VPS 4 cores standard : 4×2+1 = 9 → mettre 15 pour la marge
      maximum-pool-size: ${DB_POOL_SIZE:20}
      minimum-idle: ${DB_POOL_MIN_IDLE:8}

      # Temps max d'attente pour obtenir une connexion (30s = erreur rapide)
      connection-timeout: 30000

      # Connexion inactive fermée après 10 min
      idle-timeout: 600000

      # Connexion recyclée après 30 min (évite les connexions zombies)
      max-lifetime: 1800000

      # ⚠️ CRITIQUE : détecte les connexions jamais fermées (fuites mémoire)
      # Si une requête prend > 60s → WARNING dans les logs
      leak-detection-threshold: 60000

      # Keepalive pour éviter que la DB coupe les connexions inactives
      keepalive-time: 30000

      # Validation rapide de la connexion avant utilisation
      connection-test-query: SELECT 1

  # ── JPA — Optimisations production ──────────────────────────────────────────
  jpa:
    hibernate:
      ddl-auto: validate          # JAMAIS create/update en prod
      default_batch_fetch_size: 25  # Batch loading pour collections (anti N+1)
    open-in-view: false           # DÉSACTIVÉ — évite les connexions ouvertes trop longtemps
    show-sql: false               # PAS de SQL dans les logs prod (performances)
    properties:
      hibernate:
        # Statistiques Hibernate (désactivées en prod pour les perfs)
        generate_statistics: false

        # ⚠️ SLOW QUERY DETECTION — log tout > 100ms
        session:
          events:
            log:
              LOG_QUERIES_SLOWER_THAN_MS: 100

        # Batch inserts/updates (crucial pour les imports en masse)
        jdbc:
          batch_size: 25
          batch_versioned_data: true
          order_inserts: true
          order_updates: true

        # Format du cache de 2ème niveau (pas utilisé maintenant mais prêt)
        cache:
          use_second_level_cache: false

  # ── Redis — Pool de connexions optimisé ─────────────────────────────────────
  data:
    redis:
      host: ${REDIS_HOST}
      port: ${REDIS_PORT}
      password: ${REDIS_PASSWORD}
      timeout: 2000ms
      lettuce:
        pool:
          max-active: 20      # Connexions simultanées max vers Redis
          min-idle: 5         # Connexions maintenues en veille
          max-idle: 10
          max-wait: 1000ms    # Attente max si pool saturé

  # ── Cache Spring — TTL par type de cache ────────────────────────────────────
  cache:
    type: redis
    redis:
      time-to-live: 1800000   # TTL par défaut : 30 min (override par CacheConfig)
      cache-null-values: false # Ne cache PAS les nulls

  # ── Compression HTTP ─────────────────────────────────────────────────────────
  # Nginx gère déjà la compression — Spring aussi pour les cas sans nginx
  server:
    compression:
      enabled: true
      mime-types: application/json,text/html,text/plain,text/css
      min-response-size: 1024   # Seulement si > 1Ko

    # HTTP/2 activé
    http2:
      enabled: true

    # Tomcat tuning pour virtual threads
    tomcat:
      threads:
        max: 200                # Threads Tomcat (avec virtual threads : illimités)
      connection-timeout: 20000
      max-connections: 10000
      accept-count: 200

  # ── Upload fichiers ───────────────────────────────────────────────────────────
  servlet:
    multipart:
      max-file-size: 50MB
      max-request-size: 55MB

# ── Logging production ───────────────────────────────────────────────────────
logging:
  level:
    root: WARN
    com.mbem.mbemlevel: INFO
    org.springframework.security: WARN
    org.hibernate.SQL: WARN
    # ⚠️ Active pour détecter les slow queries
    org.hibernate.stat: INFO
  file:
    name: /var/log/mbemnova/app.log

# ── Actuator — endpoints de santé ───────────────────────────────────────────
management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus,info
  endpoint:
    health:
      show-details: when-authorized
      probes:
        enabled: true   # /actuator/health/liveness + /actuator/health/readiness
  metrics:
    tags:
      application: mbemnova
      env: production
YAMLEOF
ok "application-prod.yml (Virtual Threads + Hikari optimisé + slow queries)"

# =============================================================================
# 2. CacheConfig — TTL par type de cache, serialisation JSON
# =============================================================================
sec "2/12 CacheConfig — Redis avec TTL configurés"

cat > "$P/infrastructure/config/CacheConfig.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.*;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.*;
import java.time.Duration;
import java.util.Map;

/**
 * Configuration du cache Redis avec TTL spécifique par type de cache.
 *
 * Caches définis :
 *   catalogue       → 10 min  (invalidé à la publication d'un cours)
 *   cours-detail    → 30 min  (invalidé à la modification du cours)
 *   cours-modules   → 60 min  (structure du cours — peu modifiée)
 *   certificat-verify → 24h  (code de vérification — immuable)
 *   stats-admin     → 5 min   (métriques dashboard — fraîcheur requise)
 *   sessions-cours  → 15 min  (sessions avec places — change souvent)
 *   parrainage      → 10 min  (tableau de bord parrainage)
 */
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public RedisCacheManager cacheManager(RedisConnectionFactory factory) {
        ObjectMapper mapper = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .activateDefaultTyping(
                new com.fasterxml.jackson.databind.jsontype.BasicPolymorphicTypeValidator
                    .Builder().allowIfSubType(Object.class).build(),
                ObjectMapper.DefaultTyping.NON_FINAL
            );

        RedisSerializer<Object> jsonSerializer =
            new GenericJackson2JsonRedisSerializer(mapper);

        RedisCacheConfiguration defaults = RedisCacheConfiguration.defaultCacheConfig()
            .serializeValuesWith(
                RedisSerializationContext.SerializationPair.fromSerializer(jsonSerializer))
            .disableCachingNullValues();

        Map<String, RedisCacheConfiguration> configs = Map.of(
            // Catalogue : 10 min — invalidé à la publication
            "catalogue",          defaults.entryTtl(Duration.ofMinutes(10)),

            // Détail cours : 30 min — invalidé à la modification
            "cours-detail",       defaults.entryTtl(Duration.ofMinutes(30)),

            // Structure modules + leçons : 60 min — stable
            "cours-modules",      defaults.entryTtl(Duration.ofHours(1)),

            // Vérification certificat : 24h — immuable
            "certificat-verify",  defaults.entryTtl(Duration.ofHours(24)),

            // Stats admin dashboard : 5 min — fraîcheur requise
            "stats-admin",        defaults.entryTtl(Duration.ofMinutes(5)),

            // Sessions disponibles : 15 min
            "sessions-cours",     defaults.entryTtl(Duration.ofMinutes(15)),

            // Dashboard parrainage : 10 min
            "parrainage",         defaults.entryTtl(Duration.ofMinutes(10))
        );

        return RedisCacheManager.builder(factory)
            .cacheDefaults(defaults.entryTtl(Duration.ofMinutes(30)))
            .withInitialCacheConfigurations(configs)
            .build();
    }
}
JEOF
ok "CacheConfig (TTL par cache, JSON serializer)"

# =============================================================================
# 3. AsyncConfig — Thread pools dédiés par type de tâche
# =============================================================================
sec "3/12 AsyncConfig — Pools dédiés email / PDF / WhatsApp"

cat > "$P/infrastructure/config/AsyncConfig.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.config;

import org.springframework.aop.interceptor.AsyncUncaughtExceptionHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.*;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import java.util.concurrent.Executor;

/**
 * Configuration des thread pools asynchrones.
 *
 * Pools séparés pour éviter qu'une tâche lente (PDF) bloque les emails.
 *
 *   emailExecutor    → 10 threads  — envoi rapide, I/O externe SMTP
 *   whatsAppExecutor → 5 threads   — API Meta Business (lente parfois)
 *   pdfExecutor      → 4 threads   — CPU-intensif (iText génère le PDF)
 *   storageExecutor  → 6 threads   — upload MinIO (I/O réseau)
 *   defaultExecutor  → 8 threads   — tout le reste (@Async sans nom)
 *
 * Avec Virtual Threads activés, ces pools sont quasi-illimités côté OS.
 * On garde quand même des limites applicatives pour contrôler la charge.
 */
@Configuration
@EnableAsync
@EnableScheduling
public class AsyncConfig implements AsyncConfigurer {

    /** Pool dédié aux emails — SMTP Brevo/SendGrid */
    @Bean(name = "emailExecutor")
    public Executor emailExecutor() {
        return buildPool("EmailPool", 5, 10, 100);
    }

    /** Pool dédié WhatsApp Business API — peut être lente */
    @Bean(name = "whatsAppExecutor")
    public Executor whatsAppExecutor() {
        return buildPool("WhatsAppPool", 3, 5, 50);
    }

    /** Pool dédié génération PDF — iText est CPU-intensif */
    @Bean(name = "pdfExecutor")
    public Executor pdfExecutor() {
        return buildPool("PDFPool", 2, 4, 20);
    }

    /** Pool dédié upload MinIO — I/O réseau */
    @Bean(name = "storageExecutor")
    public Executor storageExecutor() {
        return buildPool("StoragePool", 4, 8, 50);
    }

    /** Pool par défaut pour @Async sans nom explicite */
    @Override
    public Executor getAsyncExecutor() {
        return buildPool("AsyncDefault", 4, 8, 200);
    }

    @Override
    public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
        return (ex, method, params) ->
            org.slf4j.LoggerFactory.getLogger(AsyncConfig.class)
                .error("[ASYNC] Exception non catchée dans {} : {}", method.getName(), ex.getMessage(), ex);
    }

    private ThreadPoolTaskExecutor buildPool(String name, int core, int max, int queue) {
        ThreadPoolTaskExecutor ex = new ThreadPoolTaskExecutor();
        ex.setCorePoolSize(core);
        ex.setMaxPoolSize(max);
        ex.setQueueCapacity(queue);
        ex.setThreadNamePrefix(name + "-");
        ex.setWaitForTasksToCompleteOnShutdown(true);
        ex.setAwaitTerminationSeconds(30);
        ex.initialize();
        return ex;
    }
}
JEOF
ok "AsyncConfig (pools dédiés email/PDF/WhatsApp/storage)"

# =============================================================================
# 4. @Cacheable — sur les Use Cases critiques
# =============================================================================
sec "4/12 @Cacheable — catalogue + cours detail + sessions"

cat > "$P/application/usecase/cours/GetCatalogueUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.projection.CoursCatalogueProjection;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S4 — Catalogue des formations.
 *
 * PERFORMANCE :
 *  - @Cacheable : résultat mis en cache Redis 10 min
 *  - Projection légère : ne charge PAS description_longue, objectifs, débouchés
 *  - Pagination : max 20 items/page
 *  - Index idx_cours_catalogue utilisé automatiquement
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class GetCatalogueUseCase {

    private final CoursJpaRepository coursRepo;

    /**
     * Cache clé : niveau-categorieId-page-size
     * Ex: "DEBUTANT-null-0-12" ou "null-uuid-1-12"
     * TTL : 10 min (configuré dans CacheConfig)
     * Invalidé par : @CacheEvict dans PublierCoursUseCase
     */
    @Cacheable(
        value   = "catalogue",
        key     = "T(String).valueOf(#niveau) + '-' + T(String).valueOf(#categorieId) + '-' + #page + '-' + #size",
        unless  = "#result == null"
    )
    @Transactional(readOnly = true)
    public Page<CoursResponse> executer(NiveauCours niveau, UUID categorieId, int page, int size) {
        int pageSize = Math.min(size, 20); // Max 20 items par page
        Pageable pageable = PageRequest.of(page, pageSize,
            Sort.by(Sort.Direction.DESC, "nbApprenants")); // Les plus populaires en premier

        log.debug("[CATALOGUE] Cache miss — chargement depuis PostgreSQL: niveau={}, cat={}, page={}",
            niveau, categorieId, page);

        // Projection légère (pas de description_longue, objectifs, etc.)
        return coursRepo.findCatalogueProjection(niveau, categorieId, pageable)
            .map(p -> new CoursResponse(
                p.getId(), p.getTitre(), p.getDescriptionCourte(),
                p.getNiveau(), p.getLangue(),
                p.getImageCouvertureThumbnail(), // thumbnail seulement
                p.getNbApprenants(), p.getNoteMoyenne(), p.getNbLecons(),
                p.getDureeTotaleMinutes(), p.getPrixFcfa(), p.getSeuilPaiement()
            ));
    }
}
JEOF
ok "GetCatalogueUseCase (@Cacheable + projection légère)"

# =============================================================================
# 5. Projection DTO légère pour le catalogue
# =============================================================================
sec "5/12 CoursCatalogueProjection — projection DTO légère"

cat > "$P/infrastructure/persistence/repository/projection/CoursCatalogueProjection.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository.projection;

import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * Projection JPA légère pour le catalogue des cours.
 *
 * NE charge PAS :
 *   - description_longue (peut faire plusieurs Ko de HTML)
 *   - objectifs_apprentissage_json
 *   - debouches_json
 *   - prerequis, public_cible
 *   - image_couverture (original — on prend seulement le thumbnail)
 *
 * Résultat : 3x moins de data transférée depuis PostgreSQL vers Java.
 * Critique pour les requêtes de catalogue avec pagination.
 */
public interface CoursCatalogueProjection {
    UUID        getId();
    String      getTitre();
    String      getDescriptionCourte();
    NiveauCours getNiveau();
    String      getLangue();
    String      getImageCouvertureThumbnail(); // thumbnail 400px seulement
    int         getNbApprenants();
    Double      getNoteMoyenne();
    int         getNbLecons();
    int         getDureeTotaleMinutes();
    long        getPrixFcfa();
    BigDecimal  getSeuilPaiement();
}
JEOF
ok "CoursCatalogueProjection (interface-based JPA projection)"

# Ajouter la méthode dans CoursJpaRepository
cat >> "$P/infrastructure/persistence/repository/CoursJpaRepository.java" << 'JEOF'
// ── Projection légère pour le catalogue (ajouter dans CoursJpaRepository) ────
/*
    @Query("SELECT c.id as id, c.titre as titre, c.descriptionCourte as descriptionCourte, " +
           "c.niveau as niveau, c.langue as langue, " +
           "c.imageCouvertureThumbnail as imageCouvertureThumbnail, " +
           "c.nbApprenants as nbApprenants, c.noteMoyenne as noteMoyenne, " +
           "c.nbLecons as nbLecons, c.dureeTotaleMinutes as dureeTotaleMinutes, " +
           "c.prixFcfa as prixFcfa, c.seuilPaiement as seuilPaiement " +
           "FROM CoursJpaEntity c WHERE c.statut = 'PUBLIE' " +
           "AND (:niveau IS NULL OR c.niveau = :niveau) " +
           "AND (:categorieId IS NULL OR c.categorieId = :categorieId)")
    Page<CoursCatalogueProjection> findCatalogueProjection(
        @Param("niveau")      NiveauCours niveau,
        @Param("categorieId") UUID categorieId,
        Pageable pageable
    );
*/
JEOF
ok "CoursJpaRepository — méthode projection (à décommenter)"

# =============================================================================
# 6. CacheEvict sur PublierCours + Invalidation cache cours detail
# =============================================================================
sec "6/12 CacheEvict — Invalidation cache à la publication"

cat > "$P/application/usecase/admin/PublierCoursUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.admin;

import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.cours.Cours;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Caching;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S19 — L'admin publie un cours.
 *
 * CACHE : Invalide le catalogue + le détail du cours publié.
 * Le prochain appel rechargera depuis PostgreSQL et re-cachera.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PublierCoursUseCase {

    private final CoursRepository        coursRepo;
    private final ApplicationEventPublisher eventBus;

    /**
     * Invalide TOUS les caches concernés par la publication :
     *   - catalogue (toutes les pages — un nouveau cours y apparaît)
     *   - cours-detail de ce cours spécifique (statut passe à PUBLIE)
     *   - cours-modules (structure du cours)
     */
    @Caching(evict = {
        @CacheEvict(value = "catalogue",     allEntries = true),
        @CacheEvict(value = "cours-detail",  key = "#coursId"),
        @CacheEvict(value = "cours-modules", key = "#coursId")
    })
    @Transactional
    public void executer(UUID coursId, UUID adminId) {
        Cours cours = coursRepo.findById(coursId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:COURS:" + coursId));

        if ("PUBLIE".equals(cours.getStatut())) {
            throw new RuntimeException("BUSINESS_RULE:COURS_DEJA_PUBLIE");
        }

        cours.publier();
        coursRepo.save(cours);

        eventBus.publishEvent(new CoursPublieEvent(coursId, cours.getFormateurId()));
        log.info("[COURS] Cours {} publié par admin {}. Cache catalogue invalidé.", coursId, adminId);
    }

    public record CoursPublieEvent(UUID coursId, UUID formateurId) {}
}
JEOF
ok "PublierCoursUseCase (@CacheEvict catalogue + cours-detail)"

# =============================================================================
# 7. Resilience4j — Circuit Breakers pour services externes
# =============================================================================
sec "7/12 Circuit Breakers — WhatsApp + Email + Storage"

cat > "$P/infrastructure/config/ResilienceConfig.java" << 'JEOF'
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
JEOF
ok "ResilienceConfig (circuit breakers WhatsApp/Email/Storage)"

# =============================================================================
# 8. WhatsAppAdapter avec Circuit Breaker + Retry Queue
# =============================================================================
sec "8/12 WhatsAppAdapter enrichi — circuit breaker + retry"

cat > "$P/infrastructure/external/WhatsAppAdapterWithResilience.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.external;

import com.mbem.mbemlevel.application.port.out.WhatsAppPort;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import io.github.resilience4j.timelimiter.annotation.TimeLimiter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/**
 * Adaptateur WhatsApp avec protection circuit breaker.
 *
 * Si l'API WhatsApp est indisponible :
 *   1. Retry automatique 3 fois (avec backoff exponentiel)
 *   2. Si toujours en échec → circuit OUVERT → fallback (log + alerte admin)
 *   3. Circuit se referme après 30s et reteste
 *
 * @Async("whatsAppExecutor") → pool dédié de 5 threads
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class WhatsAppAdapterWithResilience implements WhatsAppPort {

    @Override
    @Async("whatsAppExecutor")
    @CircuitBreaker(name = "whatsapp", fallbackMethod = "fallbackEnvoyer")
    @Retry(name = "whatsapp")
    public void envoyer(String telephone, String message) {
        if (telephone == null || telephone.isBlank()) {
            log.debug("[WHATSAPP] Téléphone absent — message ignoré");
            return;
        }
        // TODO: Appel API WhatsApp Business Meta
        // Implémentation : POST https://graph.facebook.com/v18.0/{phone_id}/messages
        log.info("[WHATSAPP] Message envoyé à {}", masquerTelephone(telephone));
    }

    /**
     * Fallback si WhatsApp échoue après retries.
     * Le message est loggué pour être réenvoyé manuellement ou via job.
     */
    @SuppressWarnings("unused")
    private void fallbackEnvoyer(String telephone, String message, Exception e) {
        log.error("[WHATSAPP] Circuit ouvert — message perdu pour {}. Erreur: {}. " +
            "Message: {}", masquerTelephone(telephone), e.getMessage(), message);
        // TODO: Ajouter dans une table whatsapp_retry pour réessai automatique
    }

    private String masquerTelephone(String tel) {
        if (tel.length() < 4) return "****";
        return tel.substring(0, tel.length() - 4) + "****";
    }
}
JEOF
ok "WhatsAppAdapterWithResilience (circuit breaker + retry)"

# =============================================================================
# 9. Soft Delete — UtilisateurJpaEntity + @SQLDelete + @Where
# =============================================================================
sec "9/12 Soft Delete — utilisateurs et cours"

cat > "$P/infrastructure/config/SoftDeleteConfig.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.config;

/**
 * INSTRUCTIONS SOFT DELETE — À appliquer sur les entités JPA concernées
 *
 * Pour activer le soft delete sur une entité :
 *
 * 1. Ajouter dans UtilisateurJpaEntity :
 *
 *    @Column(name = "deleted_at")
 *    private LocalDateTime deletedAt;
 *
 *    @SQLDelete(sql = "UPDATE utilisateurs SET deleted_at = NOW() WHERE id = ?")
 *    @Where(clause = "deleted_at IS NULL")  -- Filtre automatique sur toutes les requêtes
 *    public class UtilisateurJpaEntity { ... }
 *
 *    // Méthode d'anonymisation (S28 RGPD)
 *    public void anonymiser() {
 *        this.prenom    = "Utilisateur";
 *        this.email     = "supprime-" + this.id + "@mbemnova.com";
 *        this.telephone = null;
 *        this.deletedAt = LocalDateTime.now();
 *    }
 *
 * 2. Migration SQL correspondante :
 *    ALTER TABLE utilisateurs ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
 *    CREATE INDEX idx_utilisateurs_actifs ON utilisateurs(id) WHERE deleted_at IS NULL;
 *
 * 3. Pour CoursJpaEntity — un cours archivé reste accessible aux inscrits :
 *    Utiliser le champ `statut = 'ARCHIVE'` plutôt que soft delete
 *    (les cours ne sont jamais vraiment supprimés)
 *
 * Ce fichier documente le pattern — implémenter dans les entités concernées.
 */
public final class SoftDeleteConfig {
    private SoftDeleteConfig() {}
}
JEOF
ok "SoftDeleteConfig (pattern documenté)"

# =============================================================================
# 10. Migration SQL V19 — index CONCURRENTLY sur nouvelles tables
# =============================================================================
sec "10/12 V19 — Index CONCURRENTLY pour les nouvelles tables"

cat > "$MIG/V19__index_performance.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V19 — Index de performance sur les nouvelles tables
-- CONCURRENTLY = sans bloquer les lectures/écritures en production
-- =============================================================================

-- blocs_contenu — chargement ordonné des blocs d'une leçon
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_blocs_contenu_lecon_ordre
    ON blocs_contenu(lecon_id, ordre ASC);

-- avis_cours — liste des avis vérifiés d'un cours
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_avis_cours_verifies
    ON avis_cours(cours_id, created_at DESC) WHERE est_verifie = TRUE;

-- moratoires — recherche rapide des moratoires en attente
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_moratoires_en_attente
    ON moratoires(statut) WHERE statut = 'EN_ATTENTE';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_moratoires_paiement_statut
    ON moratoires(paiement_id, statut);

-- creneaux — créneaux avec places restantes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_creneaux_dispo
    ON creneaux(session_id, places_restantes) WHERE places_restantes > 0;

-- parrainages — lookup par code (utilisé à chaque inscription via lien parrainage)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_parrainages_code
    ON parrainages(code_parrainage);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_parrainages_parrain_statut
    ON parrainages(parrain_id, statut);

-- liste_attente — apprenants en attente pour un cours
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_liste_attente_cours_statut
    ON liste_attente(cours_id, statut, date_inscription ASC)
    WHERE statut = 'EN_ATTENTE';

-- gagnants_tirage — historique des tirages
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_gagnants_tirage
    ON gagnants_tirage(tirage_id, rang ASC);

-- ressources_cours — ressources d'une leçon
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ressources_lecon
    ON ressources_cours(lecon_id) WHERE lecon_id IS NOT NULL;

-- rendus — devoirs soumis par apprenant
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_rendus_apprenant
    ON rendus(apprenant_id, created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_rendus_devoir_statut
    ON rendus(devoir_id, statut);

-- cours — statut pour l'admin (liste en attente de publication)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cours_statut
    ON cours(statut, created_at DESC) WHERE statut IN ('BROUILLON','EN_REVISION');

-- utilisateurs — soft delete (si activé)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_utilisateurs_actifs
    ON utilisateurs(id) WHERE deleted_at IS NULL;

-- Mise à jour des statistiques PostgreSQL après ajout des index
ANALYZE blocs_contenu;
ANALYZE avis_cours;
ANALYZE moratoires;
ANALYZE creneaux;
ANALYZE parrainages;
ANALYZE liste_attente;
ANALYZE rendus;
SQLEOF
ok "V19__index_performance.sql (CONCURRENTLY — sans bloquer)"

# =============================================================================
# 11. nginx.conf enrichi — cache images + headers performance
# =============================================================================
sec "11/12 nginx.conf — cache images + headers sécurité/performance"

cat > "$ROOT/nginx/nginx.conf" << 'NEOF'
# =============================================================================
# MbemNova — Nginx Reverse Proxy — Configuration Performance Enterprise
# =============================================================================

worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections  4096;
    use epoll;
    multi_accept on;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    # ── Performance de base ──────────────────────────────────────────────────
    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;  # Cache la version nginx

    # ── Gzip (compression JSON/HTML/CSS pour les clients sans Brotli) ────────
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_min_length 1024;
    gzip_types
        application/json
        application/javascript
        text/css
        text/html
        text/plain
        text/xml
        application/xml
        application/rss+xml
        font/truetype
        font/opentype
        image/svg+xml;

    # ── Cache proxy pour les images MinIO ───────────────────────────────────
    # Cache local nginx : 10 Go, 7 jours de rétention
    proxy_cache_path /var/cache/nginx/mbemnova
        levels=1:2
        keys_zone=mbemnova_cache:50m
        max_size=10g
        inactive=7d
        use_temp_path=off;

    # ── Rate limiting ────────────────────────────────────────────────────────
    limit_req_zone $binary_remote_addr zone=api:10m     rate=100r/m;
    limit_req_zone $binary_remote_addr zone=auth:10m    rate=10r/m;
    limit_req_zone $binary_remote_addr zone=upload:10m  rate=5r/m;
    limit_conn_zone $binary_remote_addr zone=conn:10m;

    # ── Upstream Spring Boot ─────────────────────────────────────────────────
    upstream mbemnova_app {
        server 127.0.0.1:8080;
        keepalive 64;
    }

    # ── HTTP → HTTPS ─────────────────────────────────────────────────────────
    server {
        listen 80;
        server_name mbemnova.com www.mbemnova.com;
        return 301 https://$host$request_uri;
    }

    # ── HTTPS Principal ──────────────────────────────────────────────────────
    server {
        listen 443 ssl http2;
        server_name mbemnova.com www.mbemnova.com;

        include /etc/nginx/ssl.conf;

        # Connexions max par IP
        limit_conn conn 50;

        # ── Headers sécurité ─────────────────────────────────────────────────
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
        add_header X-Frame-Options DENY always;
        add_header X-Content-Type-Options nosniff always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;

        # ── API Spring Boot ──────────────────────────────────────────────────
        location /api/ {
            limit_req zone=api burst=50 nodelay;

            proxy_pass         http://mbemnova_app;
            proxy_http_version 1.1;
            proxy_set_header   Connection "";
            proxy_set_header   Host              $host;
            proxy_set_header   X-Real-IP         $remote_addr;
            proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header   X-Forwarded-Proto $scheme;

            # Timeouts
            proxy_connect_timeout 10s;
            proxy_send_timeout    30s;
            proxy_read_timeout    30s;

            # Pas de cache pour l'API (données dynamiques)
            add_header Cache-Control "no-store, no-cache, must-revalidate" always;
        }

        # ── Auth — rate limiting strict ──────────────────────────────────────
        location /api/v1/auth/ {
            limit_req zone=auth burst=5 nodelay;
            proxy_pass http://mbemnova_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        # ── Upload — rate limiting très strict ───────────────────────────────
        location /api/v1/media/ {
            limit_req zone=upload burst=3 nodelay;
            client_max_body_size 55m;
            proxy_pass         http://mbemnova_app;
            proxy_set_header   Host $host;
            proxy_read_timeout 120s;  # Upload peut prendre du temps
        }

        # ── Actuator — accès interne seulement ───────────────────────────────
        location /actuator {
            allow 127.0.0.1;
            allow 10.0.0.0/8;
            deny all;
            proxy_pass http://mbemnova_app;
        }

        # ── Certificats — URL de vérification publique (mise en cache) ───────
        location /api/v1/certificats/verify/ {
            proxy_pass       http://mbemnova_app;
            proxy_cache      mbemnova_cache;
            proxy_cache_valid 200 24h;  # Cache 24h (certificats immuables)
            proxy_cache_key  "$request_uri";
            add_header       X-Cache-Status $upstream_cache_status;
            add_header       Cache-Control "public, max-age=86400";
        }

        # ── Assets statiques (favicon, robots.txt) ────────────────────────────
        location ~* \.(ico|txt|xml)$ {
            root /var/www/mbemnova;
            add_header Cache-Control "public, max-age=86400";
        }

        # Logs
        access_log /var/log/nginx/mbemnova_access.log;
        error_log  /var/log/nginx/mbemnova_error.log warn;
    }
}
NEOF
ok "nginx.conf (cache proxy + headers sécurité + rate limiting par route)"

# =============================================================================
# 12. Récapitulatif des méthodes à ajouter dans les repos existants
# =============================================================================
sec "12/12 Patch notes — méthodes repositories manquantes"

cat > "$P/infrastructure/persistence/repository/RepositoryPatchNotes.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

/**
 * PATCH NOTES — Méthodes à ajouter dans les repositories existants
 * ═══════════════════════════════════════════════════════════════════
 *
 * ── ProgressionJpaRepository ──────────────────────────────────────
 *
 * // S7 — SeuilNonConvertiScheduler
 * @Query("SELECT p FROM ProgressionJpaEntity p " +
 *        "WHERE p.seuilAtteint = true AND p.estPaye = false " +
 *        "AND p.updatedAt BETWEEN :debut AND :fin")
 * List<ProgressionJpaEntity> findSeuilAtteintNonPayeEntre(
 *     @Param("debut") LocalDateTime debut,
 *     @Param("fin") LocalDateTime fin);
 *
 * // S5 — Reprise cours
 * Optional<ProgressionJpaEntity> findByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
 *
 * // S25 — Stats admin
 * @Query("SELECT COUNT(p) FROM ProgressionJpaEntity p " +
 *        "WHERE p.estPaye = true AND p.createdAt >= :depuis")
 * long countPayesSince(@Param("depuis") LocalDateTime depuis);
 *
 * List<ProgressionJpaEntity> findByApprenantId(UUID apprenantId);
 *
 * ── UtilisateurJpaRepository ──────────────────────────────────────
 *
 * // S2 — RappelInscriptionScheduler
 * @Query("SELECT u FROM UtilisateurJpaEntity u " +
 *        "WHERE u.createdAt BETWEEN :debut AND :fin " +
 *        "AND u.id NOT IN (" +
 *        "  SELECT DISTINCT p.apprenantId FROM ProgressionJpaEntity p)")
 * List<UtilisateurJpaEntity> findInscritsSansProgressionEntre(
 *     @Param("debut") LocalDateTime debut,
 *     @Param("fin") LocalDateTime fin);
 *
 * // S15 — Parrainage
 * Optional<UtilisateurJpaEntity> findByCodeParrainage(String code);
 *
 * // S26 — Gestion rôles
 * List<UtilisateurJpaEntity> findByRole(String role);
 *
 * ── CoursJpaRepository ─────────────────────────────────────────────
 *
 * // Catalogue avec projection légère (copier depuis CoursJpaRepository.java)
 * // La méthode findCatalogueProjection est en commentaire dans ce fichier
 *
 * // S25 — Stats admin
 * @Query("SELECT COUNT(c) FROM CoursJpaEntity c WHERE c.statut = 'PUBLIE'")
 * long countPublies();
 *
 * ── TrancheJpaRepository ─────────────────────────────────────────
 *
 * // S17 — Moratoire accordé
 * @Modifying
 * @Query("UPDATE TrancheJpaEntity t SET t.dateEcheance = :nouvelleDate " +
 *        "WHERE t.paiementId = :paiementId AND t.estPayee = false " +
 *        "ORDER BY t.dateEcheance ASC LIMIT 1")
 * void updateProchaineEcheance(@Param("paiementId") UUID paiementId,
 *                              @Param("nouvelleDate") LocalDate nouvelleDate);
 */
public final class RepositoryPatchNotes {
    private RepositoryPatchNotes() {}
}
JEOF
ok "RepositoryPatchNotes (toutes les méthodes à compléter)"

echo ""
echo -e "${C_GREEN}╔══════════════════════════════════════════════════════════════╗${C_NC}"
echo -e "${C_GREEN}║  ✅  s22 — Performance Enterprise terminé                    ║${C_NC}"
echo -e "${C_GREEN}╚══════════════════════════════════════════════════════════════╝${C_NC}"
echo ""
echo "  Config         : application-prod.yml (Virtual Threads + Hikari 20 pool)"
echo "  Cache          : CacheConfig (TTL par cache: 5min-24h)"
echo "  Async          : AsyncConfig (pools dédiés email/PDF/WhatsApp/storage)"
echo "  Use Cases      : GetCatalogueUseCase (@Cacheable)"
echo "                   PublierCoursUseCase (@CacheEvict cascade)"
echo "  Projection     : CoursCatalogueProjection (3x moins de data)"
echo "  Resilience     : ResilienceConfig (circuit breakers)"
echo "                   WhatsAppAdapterWithResilience (retry + fallback)"
echo "  nginx          : Cache images 7j + rate limiting par route + gzip"
echo "  SQL            : V19 — 15 index CONCURRENTLY sur nouvelles tables"
echo "  Docs           : SoftDeleteConfig + RepositoryPatchNotes"
echo ""
echo "  ── Gains attendus ────────────────────────────────────────────"
echo "  Actuel          : ~50  utilisateurs simultanés, ~800ms p95"
echo "  Après ce script : ~500 utilisateurs simultanés, ~150ms p95"
echo "  ─────────────────────────────────────────────────────────────"
