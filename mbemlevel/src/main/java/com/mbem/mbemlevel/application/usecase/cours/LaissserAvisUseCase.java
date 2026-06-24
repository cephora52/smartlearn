package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.api.dto.request.LaissserAvisRequest;
import com.mbem.mbemlevel.infrastructure.persistence.entity.AvisCoursJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S4 — Laisser un avis sur un cours.
 * Règles métier :
 *  - L'apprenant doit avoir >= 30% de progression ET avoir payé
 *  - Un seul avis par apprenant par cours — pas de modification
 *  - L'avis est marqué "vérifié" automatiquement si les conditions sont remplies
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LaissserAvisUseCase {

    private final AvisCoursJpaRepository    avisRepo;
    private final ProgressionJpaRepository  progressionRepo;

    @Transactional
    public UUID executer(UUID coursId, UUID apprenantId, LaissserAvisRequest req) {
        // Vérifier pas d'avis existant
        if (avisRepo.existsByCoursIdAndApprenantId(coursId, apprenantId)) {
            throw new RuntimeException("BUSINESS_RULE:AVIS_DEJA_SOUMIS");
        }

        // Vérifier la progression >= 30% et payée
        var progression = progressionRepo
            .findByApprenantIdAndCoursId(apprenantId, coursId)
            .orElseThrow(() -> new RuntimeException("BUSINESS_RULE:COURS_PAS_COMMENCE"));

        if (!progression.isEstPaye()) {
            throw new RuntimeException("BUSINESS_RULE:COURS_PAS_PAYE:avis_reserve_aux_payants");
        }
        if (progression.getPourcentage() < 30.0) {
            throw new RuntimeException("BUSINESS_RULE:PROGRESSION_INSUFFISANTE:minimum_30_pourcent");
        }

        // Créer l'avis vérifié
        AvisCoursJpaEntity avis = AvisCoursJpaEntity.builder()
            .id(UUID.randomUUID())
            .coursId(coursId)
            .apprenantId(apprenantId)
            .note(req.note())
            .commentaire(req.commentaire())
            .estVerifie(true) // Vérifié automatiquement car conditions remplies
            .build();
        avisRepo.save(avis);

        // Recalculer la note moyenne du cours
       double nouvelleMoyenne = avisRepo.calculerNoteMoyenne(coursId).orElse(0.0);
        // La mise à jour de la note moyenne du cours est faite via un @Scheduled quotidien
        // pour éviter une requête supplémentaire à chaque avis

        log.info("[AVIS] Avis {} étoiles déposé sur cours {} par apprenant {}", req.note(), coursId, apprenantId);
        return avis.getId();
    }
}
