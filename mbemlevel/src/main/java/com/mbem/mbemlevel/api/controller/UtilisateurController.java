package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.response.ApiResponse;
import com.mbem.mbemlevel.application.usecase.auth.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.UUID;

/**
 * Droits RGPD utilisateurs — S28
 *
 * DELETE /api/v1/utilisateurs/me        → Supprimer son compte (droit effacement)
 * GET    /api/v1/utilisateurs/me/export → Exporter ses données (portabilité)
 */
@RestController
@RequestMapping("/api/v1/utilisateurs")
@Tag(name = "RGPD", description = "Droits des utilisateurs sur leurs données — S28")
@PreAuthorize("isAuthenticated()")
@RequiredArgsConstructor
public class UtilisateurController {

    private final SupprimerCompteUseCase              supprimerUC;
    private final ExporterDonneesPersonnellesUseCase  exporterUC;

    /**
     * S28 — Droit à l'effacement.
     * Anonymise les données personnelles, révoque toutes les sessions.
     * Les données de paiement sont conservées 10 ans (obligation légale).
     */
    @DeleteMapping("/me")
    @Operation(summary = "Supprimer son compte (S28 — droit à l'effacement)")
    public ResponseEntity<ApiResponse<Void>> supprimer(
            @AuthenticationPrincipal String userId) {
        supprimerUC.executer(UUID.fromString(userId));
        return ResponseEntity.ok(
            ApiResponse.ok("Compte supprimé. Tes données personnelles seront effacées sous 30 jours."));
    }

    /**
     * S28 — Droit à la portabilité.
     * Export JSON de toutes les données personnelles.
     */
    @GetMapping("/me/export")
    @Operation(summary = "Exporter ses données personnelles en JSON (S28)")
    public ResponseEntity<ApiResponse<Map<String, Object>>> exporter(
            @AuthenticationPrincipal String userId) {
        Map<String, Object> data = exporterUC.executer(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok(data));
    }
}
