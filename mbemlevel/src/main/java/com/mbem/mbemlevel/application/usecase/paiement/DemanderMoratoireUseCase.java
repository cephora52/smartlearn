package com.mbem.mbemlevel.application.usecase.paiement;

import com.mbem.mbemlevel.api.dto.request.DemanderMoratoireRequest;
import com.mbem.mbemlevel.application.port.out.MoratoireRepository;
import com.mbem.mbemlevel.application.port.out.PaiementRepository;
import com.mbem.mbemlevel.domain.paiement.Moratoire;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S17 — L'apprenant demande un délai de paiement (moratoire).
 * Règles :
 *  - Un seul moratoire EN_ATTENTE autorisé par paiement
 *  - Les relances automatiques sont suspendues jusqu'à décision admin
 *  - L'admin reçoit une notification immédiate
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DemanderMoratoireUseCase {

    private final MoratoireRepository    moratoireRepo;
    private final PaiementRepository     paiementRepo;
    private final ApplicationEventPublisher eventBus;

    @Transactional
    public UUID executer(DemanderMoratoireRequest req, UUID apprenantId) {
        // Vérifier que le paiement appartient à l'apprenant
        paiementRepo.findByIdAndApprenantId(req.paiementId(), apprenantId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:PAIEMENT"));

        // Vérifier qu'il n'y a pas déjà un moratoire en attente
        if (moratoireRepo.existsEnAttenteForPaiement(req.paiementId())) {
            throw new RuntimeException("BUSINESS_RULE:MORATOIRE_DEJA_EN_ATTENTE");
        }

        // Construire la raison complète
        String raisonComplete = req.raison()
            + (req.explicationLibre() != null ? " — " + req.explicationLibre() : "");

        // Créer le moratoire
        Moratoire moratoire = Moratoire.creer(
            req.paiementId(), raisonComplete, req.nouvelleDateSouhaitee()
        );
        moratoireRepo.save(moratoire);

        // Notifier l'admin
        eventBus.publishEvent(new MoratoireDemandeEvent(moratoire.getId(), req.paiementId(), apprenantId));

        log.info("[MORATOIRE] Demande créée: {} pour paiement: {}", moratoire.getId(), req.paiementId());
        return moratoire.getId();
    }

    /** Événement publié vers l'admin */
    public record MoratoireDemandeEvent(UUID moratoireId, UUID paiementId, UUID apprenantId) {}
}
