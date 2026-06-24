package com.mbem.mbemlevel.infrastructure.scheduler;
import com.mbem.mbemlevel.application.usecase.gamification.EffectuerTirageAuSortUseCase;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
/**
 * S24 — Tirage au sort mensuel : 1er du mois à 08h00 Africa/Douala.
 * Prix configurable via la propriété mbemnova.gamification.prix-description.
 */
@Component @RequiredArgsConstructor @Slf4j
public class TirageAuSortScheduler {
    private final EffectuerTirageAuSortUseCase tirageUC;
    @Value("${mbemnova.gamification.prix-description:Réduction sur le prochain cours}") private String prix;

    @Scheduled(cron="0 0 8 1 * ?", zone="Africa/Douala")
    public void executerTirageMensuel() {
        log.info("[TIRAGE] Démarrage du tirage mensuel");
        try {
            tirageUC.executer(prix);
        } catch (Exception e) {
            log.error("[TIRAGE] Erreur tirage: {}", e.getMessage(), e);
        }
    }
}
