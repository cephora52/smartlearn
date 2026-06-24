package com.mbem.mbemlevel.application.usecase.progression;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.progression.Progression;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S06 — Marquer une leçon comme terminée.
 * Calcule le nouveau pourcentage, ajoute les XP, publie les events si seuil atteint.
 */
@Service @RequiredArgsConstructor
public class TerminerLeconUseCase {
    private final ProgressionRepository  progressionRepo;
    private final CoursRepository        coursRepo;
    private final ApplicationEventPublisher publisher;

    @Transactional
    public Progression executer(UUID apprenantId, UUID coursId, UUID leconId,
                                 int nbLeconsTotales, int nbLeconsTerminees,
                                 int xpLecon, String prenom, String email,
                                 String telephone, String nomCours) {
        Progression p = progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
            .orElseGet(() -> {
                var cours = coursRepo.findById(coursId)
                    .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
                return Progression.commencer(apprenantId, coursId,
    cours.getSeuilPaiement().doubleValue());
            });

        double nouveauPct = nbLeconsTotales > 0
            ? Math.min(100.0, (double) nbLeconsTerminees / nbLeconsTotales * 100.0) : 0;

        p.avancer(nouveauPct, xpLecon, prenom, email, telephone, nomCours);
        Progression saved = progressionRepo.save(p);

        // Publier les domain events (SeuilPaiementAtteintEvent, CoursTermineEvent…)
        saved.getDomainEvents().forEach(publisher::publishEvent);
        saved.clearDomainEvents();
        return saved;
    }
}
