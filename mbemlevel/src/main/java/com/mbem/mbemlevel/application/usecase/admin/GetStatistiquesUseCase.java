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

    public record Statistiques(
            long totalApprenants, long apprenantsActifs,
            long paiementsEnAttente, long paiementsEnRetard,
            long revenus) {
    }

    @Transactional(readOnly = true)
    public Statistiques executer() {
        // Comptages simplifiés — à optimiser avec des requêtes COUNT en base
        long totalApp = utilisateurRepo.findAll().stream()
                .filter(u -> "APPRENANT".equals(u.getRole().name())).count();
        long actifs = utilisateurRepo.findAll().stream()
                .filter(u -> "APPRENANT".equals(u.getRole().name())
                        && "ACTIF".equals(u.getStatut().name()))
                .count();
        long enAttente = paiementRepo.findPaiementsEnCours().stream()
                .filter(p -> "EN_ATTENTE".equals(p.getStatut().name())).count();
        long enRetard = paiementRepo.findPaiementsEnCours().stream()
                .filter(p -> "EN_RETARD".equals(p.getStatut().name())).count();
        long revenus = paiementRepo.findPaiementsEnCours().stream()
                .mapToLong(p -> p.getMontantPaye().toLong()).sum();
        return new Statistiques(totalApp, actifs, enAttente, enRetard, revenus);
    }
}
