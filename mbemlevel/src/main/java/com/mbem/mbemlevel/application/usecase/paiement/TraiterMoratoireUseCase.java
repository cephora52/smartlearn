package com.mbem.mbemlevel.application.usecase.paiement;

import com.mbem.mbemlevel.api.dto.request.TraiterMoratoireRequest;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.paiement.Moratoire;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S17 — L'admin traite une demande de moratoire.
 *
 * CORRECTION s23 :
 *   - moratoire.accorder() prend maintenant (UUID, LocalDate)
 *   - moratoire.refuser() prend (UUID, String) — inchangé
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TraiterMoratoireUseCase {

    private final MoratoireRepository      moratoireRepo;
    private final TrancheRepository        trancheRepo;
    private final ApplicationEventPublisher eventBus;

    @Transactional
    public void executer(UUID moratoireId, TraiterMoratoireRequest req, UUID adminId) {
        Moratoire moratoire = moratoireRepo.findById(moratoireId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:MORATOIRE:" + moratoireId));

        if (!"EN_ATTENTE".equals(moratoire.getStatut())) {
            throw new RuntimeException("BUSINESS_RULE:MORATOIRE_DEJA_TRAITE");
        }

        if ("ACCORDE".equals(req.decision())) {
            if (req.nouvelleDateAccordee() == null) {
                throw new RuntimeException("VALIDATION:nouvelle_date_obligatoire_si_accorde");
            }

            // CORRECTION : accorder(UUID, LocalDate) — conforme au domain corrigé
            moratoire.accorder(adminId, req.nouvelleDateAccordee());
            moratoireRepo.save(moratoire);

            // Mettre à jour la date d'échéance de la prochaine tranche
            trancheRepo.updateDateEcheance(moratoire.getPaiementId(), req.nouvelleDateAccordee());

            eventBus.publishEvent(new MoratoireDecideEvent(
                moratoireId, moratoire.getPaiementId(), "ACCORDE",
                req.nouvelleDateAccordee().toString(), null
            ));
            log.info("[MORATOIRE] Accordé: {} → {}", moratoireId, req.nouvelleDateAccordee());

        } else if ("REFUSE".equals(req.decision())) {
            if (req.justificationRefus() == null || req.justificationRefus().isBlank()) {
                throw new RuntimeException("VALIDATION:justification_obligatoire_si_refuse");
            }

            // refuser(UUID, String) — inchangé
            moratoire.refuser(adminId, req.justificationRefus());
            moratoireRepo.save(moratoire);

            eventBus.publishEvent(new MoratoireDecideEvent(
                moratoireId, moratoire.getPaiementId(), "REFUSE",
                null, req.justificationRefus()
            ));
            log.info("[MORATOIRE] Refusé: {} — {}", moratoireId, req.justificationRefus());

        } else {
            throw new RuntimeException("VALIDATION:decision_invalide:" + req.decision());
        }
    }

    public record MoratoireDecideEvent(
        UUID   moratoireId,
        UUID   paiementId,
        String decision,
        String nouvelleDateStr,
        String justificationRefus
    ) {}
}
