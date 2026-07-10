package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.request.LaissserAvisRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.cours.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

/**
 * Avis sur les cours + Liste d'attente — S4
 *
 * GET  /api/v1/cours/{coursId}/avis          → Avis vérifiés
 * POST /api/v1/cours/{coursId}/avis          → Laisser un avis
 * POST /api/v1/cours/{coursId}/liste-attente → S'inscrire en liste d'attente
 */
@RestController
@RequestMapping("/api/v1/cours")
@Tag(name = "Avis & Liste d'attente", description = "Avis vérifiés et liste d'attente — S4")
@RequiredArgsConstructor
public class AvisController {

    private final LaissserAvisUseCase         laissserAvisUC;
    private final SInscrireListeAttenteUseCase listeAttenteUC;
    private final ListerAvisUseCase            listerAvisUC;

    /** S4 — Lire les avis vérifiés d'un cours */
    @GetMapping("/{coursId}/avis")
    @Operation(summary = "Avis vérifiés d'un cours (S4)")
    public ResponseEntity<ApiResponse<List<AvisCoursResponse>>> lister(
            @PathVariable UUID coursId) {
        List<AvisCoursResponse> avis = listerAvisUC.executer(coursId);
        return ResponseEntity.ok(ApiResponse.ok(avis));
    }

    /** S4 — Laisser un avis (apprenant ayant >= 30% et ayant payé) */
    @PostMapping("/{coursId}/avis")
    @PreAuthorize("hasRole('APPRENANT')")
    @Operation(summary = "Laisser un avis vérifié (S4)")
    public ResponseEntity<ApiResponse<UUID>> laisserAvis(
            @PathVariable UUID coursId,
            @Valid @RequestBody LaissserAvisRequest req,
            @AuthenticationPrincipal String userId) {
        UUID id = laissserAvisUC.executer(coursId, UUID.fromString(userId), req);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.ok(id, "Merci pour ton avis — il aidera d'autres apprenants !"));
    }

    /** S4 — S'inscrire sur la liste d'attente quand toutes les sessions sont complètes */
    @PostMapping("/{coursId}/liste-attente")
    @PreAuthorize("hasRole('APPRENANT')")
    @Operation(summary = "S'inscrire sur la liste d'attente (S4)")
    public ResponseEntity<ApiResponse<Void>> listeAttente(
            @PathVariable UUID coursId,
            @RequestParam(required = false) UUID sessionId,
            @AuthenticationPrincipal String userId) {
        listeAttenteUC.executer(coursId, UUID.fromString(userId), sessionId);
        return ResponseEntity.ok(ApiResponse.ok(
            "Tu es sur la liste d'attente. Tu seras notifié dès qu'une place se libère."));
    }
}
