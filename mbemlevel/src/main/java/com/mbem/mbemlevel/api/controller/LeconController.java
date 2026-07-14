package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.cours.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

/**
 * API Lecture des leçons pour les apprenants.
 *
 * GET /api/v1/cours/{coursId}/modules/{moduleId}/lecons/{leconId}
 *     → Contenu complet de la leçon (blocs, QCM sans bonne réponse, ressources)
 */
@RestController
@RequestMapping("/api/v1/cours")
@Tag(name = "Leçons", description = "Contenu pédagogique des leçons")
@RequiredArgsConstructor
public class LeconController {

    private final GetLeconDetailUseCase getLeconDetailUC;

    /**
     * S6 — Ouvrir une leçon et afficher son contenu complet.
     * Retourne les blocs ordonnés (texte, image, vidéo, PDF, code, callout)
     * et le QCM de la leçon si présent (sans la bonne réponse).
     */
    @GetMapping("/{coursId}/lecons/{leconId}")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Contenu complet d'une leçon (S6)")
    public ResponseEntity<ApiResponse<LeconDetailResponse>> getLecon(
            @PathVariable UUID coursId,
            @PathVariable UUID leconId,
            @AuthenticationPrincipal String userId) {
        UUID apprenantId = userId != null ? UUID.fromString(userId) : null;
        return ResponseEntity.ok(
            ApiResponse.ok(getLeconDetailUC.executer(leconId, apprenantId))
        );
    }
}
