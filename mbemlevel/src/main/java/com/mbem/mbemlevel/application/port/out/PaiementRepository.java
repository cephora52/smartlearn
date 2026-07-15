package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.domain.paiement.Paiement;
import com.mbem.mbemlevel.domain.paiement.Tranche;
import java.time.LocalDate;
import java.util.*;

/**
 * Port sortant — Persistence des paiements.
 *
 * CORRECTION s23 : ajout de findByIdAndApprenantId()
 */
public interface PaiementRepository {

    Paiement           save(Paiement paiement);
    Optional<Paiement> findById(UUID id);

    /**
     * CORRECTION s23 — Vérification que le paiement appartient à l'apprenant.
     * Utilisé dans DemanderMoratoireUseCase pour éviter l'accès à un paiement
     * qui ne lui appartient pas (sécurité).
     */
    Optional<Paiement> findByIdAndApprenantId(UUID paiementId, UUID apprenantId);

    Optional<Paiement> findByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
    List<Paiement>     findByApprenantId(UUID apprenantId);
    List<Paiement>     findPaiementsEnCours();
    void               saveTranches(List<Tranche> tranches);
    List<Tranche>      findTranchesParPaiement(UUID paiementId);
    List<Tranche>      findTranchesEnRetard();
    List<Tranche>      findTranchesEcheantEntre(LocalDate debut, LocalDate fin);
    List<Paiement>     findAll();
}
// ── Note pour l'implémentation JPA ───────────────────────────────────────────
// Dans PaiementRepositoryAdapter.java, ajouter :
//
// @Override
// public Optional<Paiement> findByIdAndApprenantId(UUID paiementId, UUID apprenantId) {
//     return paiementJpaRepo.findByIdAndApprenantId(paiementId, apprenantId)
//         .map(paiementMapper::toDomain);
// }
//
// Dans PaiementJpaRepository.java, ajouter :
// Optional<PaiementJpaEntity> findByIdAndApprenantId(UUID id, UUID apprenantId);
