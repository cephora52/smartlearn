package com.mbem.mbemlevel.infrastructure.scheduler;

import com.mbem.mbemlevel.application.port.out.WhatsAppPort;
import com.mbem.mbemlevel.infrastructure.persistence.repository.ProgressionJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.time.LocalDateTime;

/**
 * S7 — Relance WhatsApp J+1 pour les apprenants ayant atteint le seuil
 * mais n'ayant pas encore payé.
 * Tourne une fois par jour à 10h.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class SeuilNonConvertiScheduler {

    private final ProgressionJpaRepository progressionRepo;
    private final UtilisateurJpaRepository utilisateurRepo;
    private final WhatsAppPort             whatsAppPort;

    @Scheduled(cron = "0 0 10 * * *") // Tous les jours à 10h
    public void relancerNonConvertis() {
        LocalDateTime hier = LocalDateTime.now().minusDays(1);
        LocalDateTime avantHier = LocalDateTime.now().minusDays(2);

        // Apprenants ayant atteint le seuil hier (J+1) sans payer
        var nonConvertis = progressionRepo
            .findSeuilAtteintNonPayeEntre(avantHier, hier);

        log.info("[SCHEDULER] Seuil non converti — {} apprenants à relancer", nonConvertis.size());

        for (var prog : nonConvertis) {
            utilisateurRepo.findById(prog.getApprenantId()).ifPresent(u -> {
                try {
                    if (u.getTelephone() != null) {
                        whatsAppPort.envoyerMessage(
                            u.getTelephone(),
                            String.format(
                                "Bonjour %s 👋 Tu étais à %.0f%% du cours — la suite t'attend ! " +
                                "Dis-nous si tu as des questions sur le paiement 😊 — MbemNova",
                                u.getPrenom(), prog.getPourcentage()
                            )
                        );
                    }
                } catch (Exception e) {
                    log.error("[SCHEDULER] Erreur relance non converti {}: {}", u.getEmail(), e.getMessage());
                }
            });
        }
    }
}
