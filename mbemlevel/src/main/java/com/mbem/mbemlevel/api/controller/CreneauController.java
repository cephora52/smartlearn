package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.request.ChoisirCreneauxRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.session.*;
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
 * Gestion des créneaux horaires — S10
 *
 * GET  /api/v1/sessions/{sessionId}/creneaux → Créneaux disponibles
 * POST /api/v1/sessions/{sessionId}/creneaux → Choisir ses créneaux
 */
@RestController
@RequestMapping("/api/v1/sessions")
@Tag(name = "Créneaux", description = "Choix des créneaux horaires — S10")
@RequiredArgsConstructor
public class CreneauController {

    private final GetCreneauxSessionUseCase getCreneauxUC;
    private final ChoisirCreneauxUseCase    choisirUC;

    /** S10 — Voir les créneaux disponibles d'une session */
    @GetMapping("/{sessionId}/creneaux")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Créneaux disponibles d'une session (S10)")
    public ResponseEntity<ApiResponse<List<CreneauResponse>>> disponibles(
            @PathVariable UUID sessionId) {
        return ResponseEntity.ok(ApiResponse.ok(getCreneauxUC.executer(sessionId)));
    }

    /** S10 — L'apprenant choisit ses créneaux */
    @PostMapping("/{sessionId}/creneaux")
    @PreAuthorize("hasRole('APPRENANT')")
    @Operation(summary = "Choisir ses créneaux horaires (S10)")
    public ResponseEntity<ApiResponse<Void>> choisir(
            @PathVariable UUID sessionId,
            @Valid @RequestBody ChoisirCreneauxRequest req,
            @AuthenticationPrincipal String userId) {
        choisirUC.executer(req, UUID.fromString(userId));
        return ResponseEntity.ok(
            ApiResponse.ok("Créneaux enregistrés. Tu recevras un rappel la veille de chaque séance."));
    }
}
