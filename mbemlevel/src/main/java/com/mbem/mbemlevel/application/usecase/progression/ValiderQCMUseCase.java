package com.mbem.mbemlevel.application.usecase.progression;

import com.mbem.mbemlevel.api.dto.response.ResultatQCMResponse;
import com.mbem.mbemlevel.infrastructure.persistence.repository.QCMJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S6 — Valider la réponse d'un apprenant à un QCM.
 *
 * Règles métier :
 *  - La bonne réponse est révélée APRÈS soumission (jamais avant)
 *  - Pas de limite de tentatives
 *  - Score >= 70% requis pour valider la leçon
 *  - L'explication est toujours fournie dans la réponse
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ValiderQCMUseCase {

    private final QCMJpaRepository qcmRepo;

    @Transactional(readOnly = true)
    public ResultatQCMResponse executer(UUID leconId, String reponseApprenant, UUID apprenantId) {
        var qcm = qcmRepo.findByLeconId(leconId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:QCM_POUR_LECON:" + leconId));

        boolean estCorrect = qcm.getBonneReponse().equalsIgnoreCase(reponseApprenant.trim());
        int score = estCorrect ? qcm.getScorePoints() : 0;
        boolean leconValidee = estCorrect; // Pour un QCM simple : 1 question = 100% si correct

        log.info("[QCM] Leçon {} — apprenant {} — réponse: {} — correct: {}",
            leconId, apprenantId, reponseApprenant, estCorrect);

        return new ResultatQCMResponse(
            estCorrect,
            score,
            qcm.getBonneReponse(),      // Révélée après soumission
            qcm.getExplication(),        // "La bonne réponse est X car..."
            leconValidee
        );
    }
}
