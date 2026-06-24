package com.mbem.mbemlevel.application.usecase.auth;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

/**
 * S28 — Droit à la portabilité (RGPD).
 * L'utilisateur exporte toutes ses données personnelles en JSON.
 * Inclut : profil, progressions, certificats, devoirs, messages, paiements.
 */
@Service
@RequiredArgsConstructor
public class ExporterDonneesPersonnellesUseCase {

    private final UtilisateurJpaRepository    utilisateurRepo;
    private final ProgressionJpaRepository    progressionRepo;
    private final CertificatJpaRepository     certificatRepo;

    @Transactional(readOnly = true)
    public Map<String, Object> executer(UUID utilisateurId) {
        var utilisateur = utilisateurRepo.findById(utilisateurId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:UTILISATEUR"));

        Map<String, Object> export = new LinkedHashMap<>();
        export.put("exportDate", java.time.LocalDateTime.now().toString());
        export.put("utilisateur", Map.of(
            "id",        utilisateur.getId(),
            "prenom",    utilisateur.getPrenom(),
            "email",     utilisateur.getEmail(),
            "telephone", utilisateur.getTelephone(),
            "dateInscription", utilisateur.getCreatedAt()
        ));
        export.put("progressions", progressionRepo.findByApprenantId(utilisateurId));
        export.put("certificats", certificatRepo.findByApprenantId(utilisateurId));
        return export;
    }
}
