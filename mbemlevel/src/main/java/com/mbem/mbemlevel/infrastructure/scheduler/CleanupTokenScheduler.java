// =============================================================================
// MbemNova — infrastructure/scheduler/CleanupTokenScheduler.java
//
// Nettoyage nocturne des tokens expirés et révoqués.
// Évite l'accumulation en base de données.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.scheduler;

import com.mbem.mbemlevel.application.port.out.RefreshTokenRepository;
import com.mbem.mbemlevel.application.port.out.ResetTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Scheduler de nettoyage des tokens expirés.
 *
 * <h3>Fréquence</h3>
 * <p>Chaque nuit à 02h00 (timezone Africa/Douala) — quand le trafic est minimal.</p>
 *
 * <h3>Ce que ça supprime</h3>
 * <ul>
 *   <li>Refresh tokens expirés OU révoqués</li>
 *   <li>Reset tokens expirés OU déjà utilisés</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class CleanupTokenScheduler {

    private final RefreshTokenRepository refreshTokenRepo;
    private final ResetTokenRepository   resetTokenRepo;

    /**
     * Nettoyage quotidien à 02:00 (Africa/Douala = UTC+1).
     * Cron : "0 0 2 * * ?" = chaque jour à 02:00:00.
     * La timezone est configurée dans application.yaml (SchedulerConfig).
     */
    @Scheduled(cron = "0 0 2 * * ?", zone = "Africa/Douala")
    public void nettoyerTokensExpires() {
        log.info("[CLEANUP] Démarrage nettoyage tokens expirés");

        try {
            int refreshSupprimes = refreshTokenRepo.nettoyerTokensExpires();
            int resetSupprimes   = resetTokenRepo.nettoyerTokensExpires();

            log.info("[CLEANUP] Terminé: {} refresh tokens + {} reset tokens supprimés",
                refreshSupprimes, resetSupprimes);
        } catch (Exception e) {
            log.error("[CLEANUP] Erreur nettoyage tokens: {}", e.getMessage(), e);
        }
    }
}
