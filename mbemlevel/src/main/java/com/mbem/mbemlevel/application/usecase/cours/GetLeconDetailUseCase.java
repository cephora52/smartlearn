package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

/**
 * S6 — Récupère le contenu complet d'une leçon pour l'affichage.
 * Inclut : blocs de contenu ordonnés, QCM (sans la bonne réponse), ressources.
 */
@Service
@RequiredArgsConstructor
public class GetLeconDetailUseCase {

    private final LeconJpaRepository       leconRepo;
    private final BlocContenuJpaRepository blocRepo;
    private final QCMJpaRepository         qcmRepo;
    private final RessourceCoursJpaRepository ressourceRepo;
    private final ProgressionJpaRepository progressionRepo;

    @Transactional(readOnly = true)
    public LeconDetailResponse executer(UUID leconId, UUID apprenantId) {
        LeconJpaEntity lecon = leconRepo.findById(leconId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:LECON:" + leconId));

        // Blocs de contenu dans l'ordre
        List<BlocContenuResponse> blocs = blocRepo
            .findByLeconIdOrderByOrdreAsc(leconId)
            .stream()
            .map(BlocContenuResponse::from)
            .toList();

        // QCM sans la bonne réponse (sécurité)
        QCMResponse qcmResp = qcmRepo.findByLeconId(leconId)
            .map(q -> new QCMResponse(
                q.getId(),
                q.getQuestion(),
                parseOptions(q.getOptionsJson()),
                q.getScorePoints(),
                q.getOrdre()
                // bonneReponse NON incluse ici
            ))
            .orElse(null);

        // Ressources de la leçon
        List<RessourceResponse> ressources = ressourceRepo
            .findByLeconId(leconId)
            .stream()
            .map(r -> new RessourceResponse(
                r.getId(), r.getTypeRessource(), r.getNom(),
                r.getUrlStockage(), r.getTailleOctets(), r.getMimeType()
            ))
            .toList();

        return new LeconDetailResponse(
            lecon.getId(), lecon.getModuleId(),
            lecon.getTitre(), lecon.getDescriptionCourte(),
            lecon.getOrdre(), lecon.getDureeMinutes(), lecon.getXpValeur(),
            lecon.isEstPreview(), lecon.isAQCM(),
            blocs, qcmResp, ressources
        );
    }

    @SuppressWarnings("unchecked")
    private List<Map<String,String>> parseOptions(String json) {
        // Simplifié — en production utiliser ObjectMapper
        return List.of();
    }
}
