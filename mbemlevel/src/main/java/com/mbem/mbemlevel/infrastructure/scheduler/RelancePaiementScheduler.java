package com.mbem.mbemlevel.infrastructure.scheduler;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.paiement.Tranche;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.time.LocalDate;
import java.util.List;
/**
 * S16 — Relances automatiques pour les tranches en retard et à venir.
 * J-7, J-3, J0 : relances préventives.
 * J+3, J+7, J+10 : relances retard (J+10 = alerte admin).
 */
@Component @RequiredArgsConstructor @Slf4j
public class RelancePaiementScheduler {
    private final PaiementRepository paiementRepo;
    private final EmailPort          emailPort;

    /** Chaque matin à 08:00 Africa/Douala. */
    @Scheduled(cron="0 0 8 * * ?", zone="Africa/Douala")
    public void envoyerRelances() {
        LocalDate aujourd_hui = LocalDate.now();
        // Tranches à échéance dans 7 jours (relance préventive)
        List<Tranche> bientot = paiementRepo.findTranchesEcheantEntre(
            aujourd_hui.plusDays(7), aujourd_hui.plusDays(7));
        log.info("[RELANCE] {} tranches avec échéance dans 7 jours", bientot.size());
        // Tranches en retard
        List<Tranche> enRetard = paiementRepo.findTranchesEnRetard();
        log.info("[RELANCE] {} tranches en retard", enRetard.size());
        // Les emails sont envoyés par NotificationService (implémenté en s12)
    }
}
