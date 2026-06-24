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
               com.fasterxml.jackson.databind.jsontype.BasicPolymorphicTypeValidator
    .builder().allowIfSubType(Object.class).build(),
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
