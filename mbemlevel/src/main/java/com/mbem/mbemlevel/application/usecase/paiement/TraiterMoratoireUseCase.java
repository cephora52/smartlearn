package com.mbem.mbemlevel.application.usecase.paiement;

import com.mbem.mbemlevel.api.dto.request.TraiterMoratoireRequest;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.paiement.Moratoire;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CoursJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S17 — L'admin traite une demande de moratoire.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TraiterMoratoireUseCase {

    private final MoratoireRepository      moratoireRepo;
    private final TrancheRepository        trancheRepo;
    private final ApplicationEventPublisher eventBus;
    private final PaiementRepository       paiementRepo;
    private final NotificationRepository   notificationRepo;
    private final CoursJpaRepository        coursRepo;
    private final UtilisateurJpaRepository  utilisateurRepo;
    private final EmailPort                emailPort;

    @Transactional
    public String executer(UUID moratoireId, TraiterMoratoireRequest req, UUID adminId) {
        Moratoire moratoire = moratoireRepo.findById(moratoireId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:MORATOIRE:" + moratoireId));

        if (!"EN_ATTENTE".equals(moratoire.getStatut())) {
            throw new RuntimeException("BUSINESS_RULE:MORATOIRE_DEJA_TRAITE");
        }

        var paiement = paiementRepo.findById(moratoire.getPaiementId())
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:PAIEMENT"));
        var student = utilisateurRepo.findById(paiement.getApprenantId())
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:LEARNER"));
        var cours = coursRepo.findById(paiement.getCoursId())
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:COURS"));

        if ("APPROUVE".equals(req.decision()) || "ACCORDE".equals(req.decision())) {
            if (req.nouvelleDateAccordee() == null) {
                throw new RuntimeException("VALIDATION:nouvelle_date_obligatoire_si_accorde");
            }

            moratoire.accorder(adminId, req.nouvelleDateAccordee());
            moratoireRepo.save(moratoire);

            // Mettre à jour le statut du paiement en MORATOIRE
            paiement.accorderMoratoire();
            paiementRepo.save(paiement);

            // Mettre à jour la date d'échéance de la prochaine tranche
            trancheRepo.updateDateEcheance(moratoire.getPaiementId(), req.nouvelleDateAccordee());

            // Notification in-app
            var notif = com.mbem.mbemlevel.domain.notification.Notification.creer(
                paiement.getApprenantId(),
                com.mbem.mbemlevel.domain.shared.enums.TypeNotification.INFO,
                com.mbem.mbemlevel.domain.shared.enums.CanalNotification.IN_APP,
                "Demande de délai acceptée",
                "Votre demande de délai pour la formation '" + cours.getTitre() + "' a été acceptée. Nouvelle date : " + req.nouvelleDateAccordee(),
                "/apprenant/formations"
            );
            notificationRepo.save(notif);

            // Envoi email
            try {
                emailPort.envoyerMoratoireApprouve(
                    student.getEmail(), student.getPrenom(), cours.getTitre(), req.nouvelleDateAccordee().toString()
                );
            } catch (Exception ex) {
                log.error("[MORATOIRE] Erreur envoi email approbation: {}", ex.getMessage());
            }

            eventBus.publishEvent(new MoratoireDecideEvent(
                moratoireId, moratoire.getPaiementId(), "APPROUVE",
                req.nouvelleDateAccordee().toString(), null
            ));
            log.info("[MORATOIRE] Approuvé: {} → {}", moratoireId, req.nouvelleDateAccordee());

        } else if ("REFUSE".equals(req.decision())) {
            if (req.justificationRefus() == null || req.justificationRefus().isBlank()) {
                throw new RuntimeException("VALIDATION:justification_obligatoire_si_refuse");
            }

            moratoire.refuser(adminId, req.justificationRefus());
            moratoireRepo.save(moratoire);

            // Notification in-app
            var notif = com.mbem.mbemlevel.domain.notification.Notification.creer(
                paiement.getApprenantId(),
                com.mbem.mbemlevel.domain.shared.enums.TypeNotification.INFO,
                com.mbem.mbemlevel.domain.shared.enums.CanalNotification.IN_APP,
                "Demande de délai refusée",
                "Votre demande de délai pour la formation '" + cours.getTitre() + "' a été refusée. Justification : " + req.justificationRefus(),
                "/apprenant/formations"
            );
            notificationRepo.save(notif);

            // Envoi email
            try {
                emailPort.envoyerMoratoireRefuse(
                    student.getEmail(), student.getPrenom(), cours.getTitre(), req.justificationRefus()
                );
            } catch (Exception ex) {
                log.error("[MORATOIRE] Erreur envoi email refus: {}", ex.getMessage());
            }

            eventBus.publishEvent(new MoratoireDecideEvent(
                moratoireId, moratoire.getPaiementId(), "REFUSE",
                null, req.justificationRefus()
            ));
            log.info("[MORATOIRE] Refusé: {} — {}", moratoireId, req.justificationRefus());

        } else {
            throw new RuntimeException("VALIDATION:decision_invalide:" + req.decision());
        }

        return (student.getPrenom() != null ? student.getPrenom() : "") 
            + (student.getNom() != null ? " " + student.getNom() : "");
    }

    public record MoratoireDecideEvent(
        UUID   moratoireId,
        UUID   paiementId,
        String decision,
        String nouvelleDateStr,
        String justificationRefus
    ) {}
}
