package com.mbem.mbemlevel.application.usecase.progression;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.progression.Progression;
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
