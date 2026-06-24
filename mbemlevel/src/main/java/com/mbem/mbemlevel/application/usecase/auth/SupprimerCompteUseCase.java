package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.infrastructure.security.token.TokenBlacklistService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S28 — Droit à l'effacement (RGPD).
 * L'utilisateur supprime son compte.
 * Règles :
 *  - Données personnelles supprimées sous 30 jours
 *  - Données de paiement conservées 10 ans (obligation légale)
 *  - Certificats rendus anonymes (pas supprimés — preuve de complétion)
 *  - Toutes les sessions JWT révoquées immédiatement
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class SupprimerCompteUseCase {

    private final UtilisateurRepository utilisateurRepo;
    private final TokenBlacklistService tokenBlacklistService;
    private final AuditLogRepository    auditRepo;

    @Transactional
    public void executer(UUID utilisateurId) {
        var utilisateur = utilisateurRepo.findById(utilisateurId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:UTILISATEUR"));

        // 1. Révoquer toutes les sessions actives
        tokenBlacklistService.revoquerToutesSessionsUtilisateur(utilisateurId);

        // 2. Anonymiser les données personnelles (soft delete)
        utilisateur.anonymiser(); // Efface prénom, email, téléphone, remplace par "Utilisateur supprimé"
        utilisateurRepo.save(utilisateur);

        // 3. Logger la suppression (obligation légale)
        auditRepo.enregistrer(utilisateurId, null, "COMPTE_SUPPRIME",
            "UTILISATEUR", utilisateurId.toString(), null, "SUCCESS", null, null);

        log.info("[RGPD] Compte supprimé et anonymisé: {}", utilisateurId);
    }
}
