package com.mbem.mbemlevel.application.usecase.session;

import com.mbem.mbemlevel.api.dto.request.CreerSessionRequest;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S20 — L'admin crée une session de formation avec ses créneaux.
 * Règles :
 *  - Vérification des conflits horaires du formateur
 *  - Génération de l'emploi du temps PDF (via EmploiDuTempsPort)
 *  - Notification aux apprenants inscrits
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CreerSessionUseCase {

    private final SessionJpaRepository  sessionRepo;
    private final CreneauJpaRepository  creneauRepo;
    private final ApplicationEventPublisher eventBus;

    @Transactional
    public UUID executer(CreerSessionRequest req, UUID adminId) {
        // Vérifier conflits horaires formateur
        boolean conflit = verifierConflitFormateur(req.formateurId(), req.dateDebut(), req.dateFin());
        if (conflit) {
            throw new RuntimeException("BUSINESS_RULE:CONFLIT_HORAIRE_FORMATEUR");
        }

        // Créer la session
        UUID sessionId = UUID.randomUUID();
        SessionJpaEntity session = SessionJpaEntity.builder()
            .id(sessionId)
            .coursId(req.coursId())
            .formateurId(req.formateurId())
            .dateDebut(req.dateDebut().atStartOfDay())
            .dateFin(req.dateFin().atTime(23, 59))
            .modalite(req.modalite())
            .lieuOuLien(req.lieuOuLien())
            .capaciteMax(req.capaciteMax())
            .placesDisponibles(req.capaciteMax())
            .statut("PLANIFIEE")
            .build();
        sessionRepo.save(session);

        // Créer les créneaux
        for (int i = 0; i < req.creneaux().size(); i++) {
            var cr = req.creneaux().get(i);
            CreneauJpaEntity creneau = CreneauJpaEntity.builder()
                .id(UUID.randomUUID())
                .sessionId(sessionId)
                .jourSemaine(cr.jourSemaine())
                .heureDebut(cr.heureDebut())
                .dureeMinutes(cr.dureeMinutes())
                .capaciteMax(cr.capaciteMax())
                .placesRestantes(cr.capaciteMax())
                .build();
            creneauRepo.save(creneau);
        }

        // Publier événement → génération PDF + notifications apprenants
        eventBus.publishEvent(new SessionCreeeEvent(sessionId, req.coursId(), req.formateurId()));
        log.info("[SESSION] Session créée: {} pour cours: {}", sessionId, req.coursId());
        return sessionId;
    }

    private boolean verifierConflitFormateur(UUID formateurId, java.time.LocalDate debut,
                                              java.time.LocalDate fin) {
        return sessionRepo.existsByFormateurIdAndPeriodeChevauchante(
            formateurId, debut.atStartOfDay(), fin.atTime(23, 59)
        );
    }

    public record SessionCreeeEvent(UUID sessionId, UUID coursId, UUID formateurId) {}
}
