package com.mbem.mbemlevel.infrastructure.scheduler;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.application.usecase.paiement.SuspendreCompteUseCase;
import com.mbem.mbemlevel.domain.paiement.Paiement;
import com.mbem.mbemlevel.domain.paiement.Tranche;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.time.LocalDate;
import java.util.List;
/**
 * S18 — Suspend automatiquement les apprenants avec retard >= J+10.
 * Lancé chaque nuit à 01:00 Africa/Douala.
 */
@Component @RequiredArgsConstructor @Slf4j
public class SuspensionScheduler {
    private final PaiementRepository     paiementRepo;
    private final SuspendreCompteUseCase suspendreUC;

    @Scheduled(cron="0 0 1 * * ?", zone="Africa/Douala")
    public void suspendreComptesEnRetardJ10() {
        LocalDate seuilJ10 = LocalDate.now().minusDays(10);
        List<Tranche> retards = paiementRepo.findTranchesEnRetard();
        int nb = 0;
        for (Tranche t : retards) {
            if (t.getDateEcheance().isBefore(seuilJ10)) {
                paiementRepo.findById(t.getPaiementId()).ifPresent(p -> {
                    try {
                        suspendreUC.executer(p.getApprenantId(), null,
                            "Retard de paiement supérieur à 10 jours.");
                    } catch (Exception e) {
                        log.warn("[SUSPENSION] Erreur: {}", e.getMessage());
                    }
                });
                nb++;
            }
        }
        if (nb > 0) log.info("[SUSPENSION] {} comptes suspendus (retard >= J+10)", nb);
    }
}
