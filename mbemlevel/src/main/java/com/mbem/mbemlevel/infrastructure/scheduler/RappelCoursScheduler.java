package com.mbem.mbemlevel.infrastructure.scheduler;
import com.mbem.mbemlevel.application.port.out.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
/**
 * Rappel 48h si un apprenant inscrit n'a pas commencé son cours.
 * Chaque jour à 09:00 Africa/Douala.
 */
@Component @RequiredArgsConstructor @Slf4j
public class RappelCoursScheduler {
    private final ProgressionRepository progressionRepo;
    private final EmailPort             emailPort;

    @Scheduled(cron="0 0 9 * * ?", zone="Africa/Douala")
    public void envoyerRappels48h() {
        // La logique de filtrage des apprenants inactifs 48h
        // est implémentée dans AdminController (s13)
        log.debug("[RAPPEL-48H] Vérification apprenants inactifs");
    }
}
