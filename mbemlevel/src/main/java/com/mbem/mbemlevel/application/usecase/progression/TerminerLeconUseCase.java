package com.mbem.mbemlevel.application.usecase.progression;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.progression.Progression;
import com.mbem.mbemlevel.infrastructure.persistence.entity.UtilisateurJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
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
    private final UtilisateurJpaRepository utilisateurRepo;
    private final com.mbem.mbemlevel.infrastructure.persistence.repository.XpHistoriqueJpaRepository xpHistoriqueRepo;
    private final ApplicationEventPublisher publisher;
    private final com.mbem.mbemlevel.infrastructure.persistence.repository.LeconJpaRepository leconRepo;
    private final com.mbem.mbemlevel.infrastructure.persistence.repository.PaiementJpaRepository paiementRepo;
    private final com.mbem.mbemlevel.infrastructure.persistence.repository.MoratoireJpaRepository moratoireRepo;

    @Transactional
    public Progression executer(UUID apprenantId, UUID coursId, UUID leconId,
                                 int nbLeconsTotales, int nbLeconsTerminees,
                                 int xpLecon, String prenom, String email,
                                 String telephone, String nomCours) {
        // Vérification du verrouillage de la leçon
        var lecon = leconRepo.findById(leconId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:LECON:" + leconId));

        var coursForCheck = coursRepo.findById(coursId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:COURS:" + coursId));

        boolean isFormateur = apprenantId.equals(coursForCheck.getFormateurId());
        boolean isAdmin = utilisateurRepo.findById(apprenantId)
            .map(u -> u.getRole() == com.mbem.mbemlevel.domain.shared.enums.Role.ADMIN || u.getRole() == com.mbem.mbemlevel.domain.shared.enums.Role.SUPER_ADMIN)
            .orElse(false);

        boolean aMoratoireApprouve = false;
        var paiementOpt = paiementRepo.findByApprenantIdAndCoursId(apprenantId, coursId);
        if (paiementOpt.isPresent()) {
            aMoratoireApprouve = moratoireRepo.existsByPaiementIdAndStatut(paiementOpt.get().getId(), "APPROUVE")
                              || moratoireRepo.existsByPaiementIdAndStatut(paiementOpt.get().getId(), "ACCORDE");
        }

        var progressionOpt = progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId);
        boolean estPaye = (progressionOpt.isPresent() && progressionOpt.get().isEstPaye())
            || (coursForCheck.getPrixFcfa() == 0)
            || isFormateur || isAdmin;

        var lecons = leconRepo.findByCoursIdOrderByOrdreAsc(coursId);
        int totalLecons = lecons.size();
        double seuilVal = coursForCheck.getSeuilPaiement().doubleValue();
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
        Progression p = progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
            .orElseGet(() -> {
                var cours = coursRepo.findById(coursId)
                    .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
                var prog = Progression.commencer(apprenantId, coursId,
    cours.getSeuilPaiement().doubleValue());
                if (cours.getPrixFcfa() == 0) {
                    prog.activerPaiement();
                }
                return prog;
            });

        // Si le cours est gratuit, on s'assure qu'il est marqué comme payé/débloqué
        var coursOpt = coursRepo.findById(coursId);
        if (coursOpt.isPresent() && coursOpt.get().getPrixFcfa() == 0) {
            p.activerPaiement();
        }

        boolean alreadyDone = p.isLeconTerminee(leconId);
        p.marquerLeconTerminee(leconId);

        // Calcule le nombre de leçons uniques terminées
        int finishedCount = 0;
        if (p.getLeconsTerminees() != null && !p.getLeconsTerminees().isBlank()) {
            finishedCount = p.getLeconsTerminees().split(",").length;
        }

        double nouveauPct = nbLeconsTotales > 0
            ? Math.min(100.0, (double) finishedCount / nbLeconsTotales * 100.0) : 0;

        String resolvedNomCours = nomCours;
        if (resolvedNomCours == null || resolvedNomCours.isBlank()) {
            resolvedNomCours = coursRepo.findById(coursId)
                .map(com.mbem.mbemlevel.domain.cours.Cours::getTitre)
                .orElse("Cours");
        }

        int xpToAward = alreadyDone ? 0 : xpLecon;
        int totalXpAwardedThisTime = xpToAward;

        if (nouveauPct >= 100.0 && p.getDateCompletion() == null) {
            // Bonus completion de formation : 200 XP
            totalXpAwardedThisTime += 200;
            p.avancer(nouveauPct, xpToAward + 200, prenom, email, telephone, resolvedNomCours);
        } else {
            p.avancer(nouveauPct, xpToAward, prenom, email, telephone, resolvedNomCours);
        }

        Progression saved = progressionRepo.save(p);

        // Enregistrer dans l'historique des gains XP
        if (totalXpAwardedThisTime > 0) {
            xpHistoriqueRepo.save(com.mbem.mbemlevel.infrastructure.persistence.entity.XpHistoriqueJpaEntity.builder()
                .id(UUID.randomUUID())
                .apprenantId(apprenantId)
                .xpGagne(totalXpAwardedThisTime)
                .dateGain(java.time.LocalDateTime.now())
                .build());
        }

        // Met à jour l'XP total de l'utilisateur dans la base de données
        utilisateurRepo.findById(apprenantId).ifPresent(userEntity -> {
            int totalXp = progressionRepo.findByApprenantId(apprenantId).stream()
                .mapToInt(Progression::getXpGagne)
                .sum();
            userEntity.setXpTotal(totalXp);
            utilisateurRepo.save(userEntity);
        });

        // Publier les domain events (SeuilPaiementAtteintEvent, CoursTermineEvent…)
        saved.getDomainEvents().forEach(publisher::publishEvent);
        saved.clearDomainEvents();
        return saved;
    }
}
