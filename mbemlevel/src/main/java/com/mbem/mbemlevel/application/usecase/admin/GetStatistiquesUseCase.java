package com.mbem.mbemlevel.application.usecase.admin;

import com.mbem.mbemlevel.application.port.out.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/*
 * S25 — Tableau de bord admin : métriques globales en temps réel.
 * Retourne un record agrégé depuis plusieurs repositories.
 */

@Service
@RequiredArgsConstructor
public class GetStatistiquesUseCase {
    private final UtilisateurRepository utilisateurRepo;
    private final PaiementRepository paiementRepo;
    private final CoursRepository coursRepo;

    public record Statistiques(
            long totalApprenants,
            long apprenantsActifs,
            long formateursActifs,
            long totalFormations,
            long paiementsEnAttente) {
    }

    @Transactional(readOnly = true)
    public Statistiques executer() {
        long totalApp = utilisateurRepo.findAll().stream()
                .filter(u -> "APPRENANT".equals(u.getRole().name())).count();
        long actifs = utilisateurRepo.findAll().stream()
                .filter(u -> "APPRENANT".equals(u.getRole().name())
                        && "ACTIF".equals(u.getStatut().name()))
                .count();
        long formateurs = utilisateurRepo.findAll().stream()
                .filter(u -> "FORMATEUR".equals(u.getRole().name()))
                .count();
        long totalFormations = coursRepo.count();
        long enAttente = paiementRepo.findPaiementsEnCours().stream()
                .filter(p -> "EN_ATTENTE".equals(p.getStatut().name())).count();
        
        return new Statistiques(totalApp, actifs, formateurs, totalFormations, enAttente);
    }
}
