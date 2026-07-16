package com.mbem.mbemlevel.application.usecase.progression;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.progression.Progression;
import com.mbem.mbemlevel.domain.paiement.Paiement;
import com.mbem.mbemlevel.domain.shared.enums.ModePaiement;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S05 — Commencer ou reprendre un cours.
 * Si progression existante → renvoyer l'existante (reprise silencieuse).
 */
@Service @RequiredArgsConstructor @Slf4j
public class CommencerCoursUseCase {
    private final ProgressionRepository progressionRepo;
    private final CoursRepository       coursRepo;
    private final PaiementRepository     paiementRepo;

    @Transactional
    public Progression executer(UUID apprenantId, UUID coursId) {
        // Reprise si déjà commencé
        return progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
            .orElseGet(() -> {
                var cours = coursRepo.findById(coursId)
                    .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
                  var progression = Progression.commencer(apprenantId, coursId, cours.getSeuilPaiement().doubleValue());
                  if (cours.getPrixFcfa() == 0) {
                      progression.activerPaiement();
                  } else {
                      // Créer le paiement en attente s'il n'existe pas déjà
                      if (paiementRepo.findByApprenantIdAndCoursId(apprenantId, coursId).isEmpty()) {
                          var p = Paiement.creer(apprenantId, coursId, (long) cours.getPrixFcfa(), ModePaiement.CASH);
                          paiementRepo.save(p);
                      }
                  }
                 var saved = progressionRepo.save(progression);
                 // Incrémenter le compteur d'apprenants du cours
                 cours.incrementerNbApprenants();
                 coursRepo.save(cours);
                 log.info("[COURS] Cours {} commencé par apprenant {}", coursId, apprenantId);
                 return saved;
            });
    }
}
