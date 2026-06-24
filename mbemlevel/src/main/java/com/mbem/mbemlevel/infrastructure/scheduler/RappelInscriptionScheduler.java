package com.mbem.mbemlevel.infrastructure.scheduler;

import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.time.LocalDateTime;

/**
 * S2 — Relance automatique 48h après inscription si l'apprenant n'a pas commencé de cours.
 * Tourne toutes les heures — vérifie les comptes inactifs depuis 48h exactement.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class RappelInscriptionScheduler {

    private final UtilisateurJpaRepository utilisateurRepo;
    private final EmailPort                emailPort;

    @Scheduled(cron = "0 0 * * * *") // Toutes les heures
    public void rappelerInactifs48h() {
        LocalDateTime debut = LocalDateTime.now().minusHours(49);
        LocalDateTime fin   = LocalDateTime.now().minusHours(47);

        var inactifs = utilisateurRepo.findInscritsSansProgressionEntre(debut, fin);
        log.info("[SCHEDULER] Rappel 48h — {} apprenants inactifs", inactifs.size());

        for (var u : inactifs) {
            try {
               emailPort.envoyerRappel48h(u.getEmail(), u.getPrenom());
            } catch (Exception e) {
                log.error("[SCHEDULER] Erreur rappel 48h pour {}: {}", u.getEmail(), e.getMessage());
            }
        }
    }
}
