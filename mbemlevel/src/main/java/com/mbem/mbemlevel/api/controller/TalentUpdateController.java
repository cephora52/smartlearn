package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.request.MettreAJourProfilRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.talent.MettreAJourProfilUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Mise à jour du profil talent — S14
 *
 * PUT  /api/v1/talents/me        → Mettre à jour son profil
 * POST /api/v1/talents/me/cv     → Uploader son CV (PDF)
 */
@RestController
@RequestMapping("/api/v1/talents")
@Tag(name = "Profil Talent", description = "Gestion du profil et CV — S14")
@PreAuthorize("hasRole('APPRENANT')")
@RequiredArgsConstructor
public class TalentUpdateController {

    private final MettreAJourProfilUseCase mettreAJourUC;

    /** S14 — Mettre à jour son profil talent */
@PutMapping("/me")
@Operation(summary = "Mettre à jour son profil (S14)")
public ResponseEntity<ApiResponse<ProfilTalentResponse>> mettreAJour(
        @Valid @RequestBody MettreAJourProfilRequest req,
        @AuthenticationPrincipal String userId) {
    
    // Créer la commande avec ce que vous avez
    var commande = new MettreAJourProfilUseCase.Commande(
        UUID.fromString(userId),
        req.prenom(),
        req.nom(),
        req.telephone(),
        false  // disponiblePourEmploi par défaut
    );
    
    // Exécuter le use case
    var utilisateur = mettreAJourUC.executer(commande);
    
    // Retourner la réponse
    return ResponseEntity.ok(ApiResponse.ok(
        ProfilTalentResponse.from(utilisateur, List.of()), 
        "Profil mis à jour."
    ));
}
}
