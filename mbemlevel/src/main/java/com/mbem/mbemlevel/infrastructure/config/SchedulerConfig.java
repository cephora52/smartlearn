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
