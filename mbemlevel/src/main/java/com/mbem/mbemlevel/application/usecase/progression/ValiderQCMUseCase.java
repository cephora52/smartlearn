package com.mbem.mbemlevel.application.usecase.progression;

import com.mbem.mbemlevel.api.dto.response.ResultatQCMResponse;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
import java.util.List;

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
    private final LeconJpaRepository leconRepo;
    private final CoursJpaRepository coursRepo;
    private final UtilisateurJpaRepository utilisateurRepo;
    private final PaiementJpaRepository paiementRepo;
    private final MoratoireJpaRepository moratoireRepo;
    private final ProgressionJpaRepository progressionRepo;

    @Transactional(readOnly = true)
    public ResultatQCMResponse executer(UUID leconId, String reponseApprenant, UUID apprenantId) {
        // Vérification du verrouillage de la leçon
        var lecon = leconRepo.findById(leconId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:LECON:" + leconId));

        UUID coursId = lecon.getCoursId();
        CoursJpaEntity cours = coursRepo.findById(coursId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:COURS:" + coursId));

        boolean isFormateur = apprenantId != null && apprenantId.equals(cours.getFormateurId());
        boolean isAdmin = false;
        if (apprenantId != null) {
            isAdmin = utilisateurRepo.findById(apprenantId)
                .map(u -> u.getRole() == com.mbem.mbemlevel.domain.shared.enums.Role.ADMIN || u.getRole() == com.mbem.mbemlevel.domain.shared.enums.Role.SUPER_ADMIN)
                .orElse(false);
        }

        boolean aMoratoireApprouve = false;
        if (apprenantId != null) {
            var paiementOpt = paiementRepo.findByApprenantIdAndCoursId(apprenantId, coursId);
            if (paiementOpt.isPresent()) {
                aMoratoireApprouve = moratoireRepo.existsByPaiementIdAndStatut(paiementOpt.get().getId(), "APPROUVE")
                                  || moratoireRepo.existsByPaiementIdAndStatut(paiementOpt.get().getId(), "ACCORDE");
            }
        }

        boolean estPaye = (cours.getPrixFcfa() == 0)
            || (apprenantId != null && progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
                .map(ProgressionJpaEntity::isEstPaye).orElse(false))
            || isFormateur || isAdmin;

        List<LeconJpaEntity> lecons = leconRepo.findByCoursIdOrderByOrdreAsc(coursId);
        int totalLecons = lecons.size();
        double seuilVal = cours.getSeuilPaiement().doubleValue();
        int maxLeconsGratuites = (int) Math.ceil(totalLecons * seuilVal);

        int leconIndex = -1;
        for (int i = 0; i < totalLecons; i++) {
            if (lecons.get(i).getId().equals(leconId)) {
                leconIndex = i;
                break;
            }
        }

        boolean estDansSeuilGratuit = (leconIndex >= 0 && leconIndex < maxLeconsGratuites);
        boolean accessible = lecon.isEstPreview() || estDansSeuilGratuit || estPaye || aMoratoireApprouve;

        if (!accessible) {
            throw new com.mbem.mbemlevel.api.exception.AccesInterditException("Cette leçon est verrouillée. Veuillez payer ou demander un moratoire.");
        }

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
