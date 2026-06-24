package com.mbem.mbemlevel.application.usecase.gamification;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

/**
 * S15 — Récupérer le tableau de bord de parrainage de l'apprenant.
 * Retourne : lien unique, message WhatsApp pré-rempli, liste des filleuls.
 */
@Service
@RequiredArgsConstructor
public class GetParrainageUseCase {

    private final ParrainageJpaRepository parrainageRepo;
    private final UtilisateurJpaRepository utilisateurRepo;

    @Transactional(readOnly = true)
    public ParrainageResponse executer(UUID parrainId) {
        // Récupérer le code de parrainage de l'apprenant
        var utilisateur = utilisateurRepo.findById(parrainId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:UTILISATEUR"));

        String code = utilisateur.getCodeParrainage();
        String lien = "https://mbemnova.com/ref/" + code;
        String messageWA = "Je me forme à la tech avec MbemNova 🚀 " +
            "Commence avec moi et on débloque tous les deux un module bonus : " + lien;

        // Filleuls
        var parrainages = parrainageRepo.findByParrainId(parrainId);
        int xpTotal = parrainages.stream().mapToInt(p -> p.getXpParrainCredite()).sum();
        long nbActifs = parrainages.stream().filter(p -> !"EN_ATTENTE".equals(p.getStatut())).count();

        List<FilleulSommaireResponse> filleuls = parrainages.stream()
            .map(p -> {
                String prenom = p.getFilleulId() != null
                    ? utilisateurRepo.findById(p.getFilleulId())
                        .map(u -> u.getPrenom()).orElse("Inconnu")
                    : "En attente";
                return new FilleulSommaireResponse(
                    prenom, p.getStatut(), p.getDateInscription(), p.getXpParrainCredite()
                );
            })
            .toList();

        return new ParrainageResponse(
            code, lien, messageWA,
            parrainages.size(), (int) nbActifs, xpTotal, filleuls
        );
    }
}
