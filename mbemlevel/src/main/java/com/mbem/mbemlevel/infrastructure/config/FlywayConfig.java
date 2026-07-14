package com.mbem.mbemlevel.infrastructure.config;
 
import org.flywaydb.core.Flyway;
import org.springframework.context.annotation.Configuration;
import javax.sql.DataSource;
import lombok.extern.slf4j.Slf4j;
 
@Configuration
@Slf4j
public class FlywayConfig {
 
    public FlywayConfig(DataSource dataSource) {
        log.info("[FLYWAY] Démarrage des migrations programmées...");
        try {
            Flyway flyway = Flyway.configure()
                .dataSource(dataSource)
                .baselineOnMigrate(true)
                .baselineVersion("22")
                .locations("classpath:db/migration")
                .outOfOrder(false)
                .load();
            
            flyway.migrate();
            log.info("[FLYWAY] Migrations terminées avec succès.");
        } catch (Exception e) {
            log.error("[FLYWAY] Erreur lors de l'exécution des migrations", e);
            throw e;
        }
    }
}
