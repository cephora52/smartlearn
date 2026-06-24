package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.gamification.GetParrainageUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * Système de parrainage — S15
 *
 * GET /api/v1/parrainage/mon-lien    → Lien unique + message WhatsApp pré-rempli
 * GET /api/v1/parrainage/mes-filleuls → Tableau de bord filleuls + récompenses
 */
@RestController
@RequestMapping("/api/v1/parrainage")
@Tag(name = "Parrainage", description = "Système de parrainage — S15")
@PreAuthorize("hasRole('APPRENANT')")
@RequiredArgsConstructor
public class ParrainageController {

    private final GetParrainageUseCase getParrainageUC;

    /** S15 — Récupérer le lien de parrainage + message WhatsApp pré-rempli */
    @GetMapping("/mon-lien")
    @Operation(summary = "Mon lien de parrainage (S15)")
    public ResponseEntity<ApiResponse<ParrainageResponse>> monLien(
            @AuthenticationPrincipal String userId) {
        var resp = getParrainageUC.executer(java.util.UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok(resp));
    }

    /** S15 — Tableau de bord : filleuls + statuts + XP gagnés */
    @GetMapping("/mes-filleuls")
    @Operation(summary = "Mes filleuls et récompenses (S15)")
    public ResponseEntity<ApiResponse<ParrainageResponse>> mesFilleuls(
            @AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(
            ApiResponse.ok(getParrainageUC.executer(java.util.UUID.fromString(userId))));
    }
}
