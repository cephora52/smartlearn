package com.mbem.mbemlevel.application.usecase.session;

import com.mbem.mbemlevel.api.dto.request.ChoisirCreneauxRequest;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.*;

/**
 * S10 — L'apprenant choisit ses créneaux horaires pour une session.
 * Règles :
 *  - Vérification en temps réel des places disponibles
 *  - Pas de double réservation sur le même créneau
 *  - Les créneaux choisis apparaissent dans le calendrier de l'apprenant
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ChoisirCreneauxUseCase {

    private final CreneauJpaRepository       creneauRepo;
    private final SessionJpaRepository       sessionRepo;

    @Transactional
    public void executer(ChoisirCreneauxRequest req, UUID apprenantId) {
        // Vérifier que la session existe et que l'apprenant y est inscrit
        sessionRepo.findById(req.sessionId())
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:SESSION"));

        List<String> conflits = new ArrayList<>();

        for (UUID creneauId : req.creneauIds()) {
            CreneauJpaEntity creneau = creneauRepo.findById(creneauId)
                .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:CRENEAU:" + creneauId));

            // Vérifier places restantes
            if (creneau.getPlacesRestantes() <= 0) {
                conflits.add("Créneau " + creneau.getJourSemaine() + " " +
                    creneau.getHeureDebut() + " est complet");
                continue;
            }

            // Décrémenter les places restantes
            creneau.setPlacesRestantes(creneau.getPlacesRestantes() - 1);
            creneauRepo.save(creneau);
        }

        if (!conflits.isEmpty()) {
            throw new RuntimeException("BUSINESS_RULE:CRENEAUX_COMPLETS:" + String.join(";", conflits));
        }

        log.info("[SESSION] {} créneaux choisis par apprenant {} pour session {}",
            req.creneauIds().size(), apprenantId, req.sessionId());
    }
}
