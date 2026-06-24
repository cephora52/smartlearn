package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.cours.*;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

/**
 * API publique des cours — Catalogue et détail de formation.
 *
 * GET /api/v1/cours                     → Catalogue filtrable + paginé (S4)
 * GET /api/v1/cours/{coursId}           → Détail complet avec modules/leçons (S4)
 * GET /api/v1/cours/slug/{slug}         → Détail par slug SEO (S4)
 * GET /api/v1/cours/{coursId}/modules   → Arbre modules + leçons uniquement
 */
@RestController
@RequestMapping("/api/v1/cours")
@Tag(name = "Cours", description = "Catalogue et détail de formation — S1, S4")
@RequiredArgsConstructor
public class CoursController {

    private final GetCatalogueUseCase     catalogueUC;
    private final GetCoursDetailUseCase   detailUC;

    /**
     * S4 — Catalogue des formations avec filtres.
     * Accessible sans connexion.
     * Filtres : niveau (DEBUTANT/INTERMEDIAIRE/AVANCE), catégorie, pagination.
     */
    @GetMapping
    @Operation(summary = "Catalogue des formations filtrable (S4)")
    public ResponseEntity<ApiResponse<PageResponse<CoursResponse>>> catalogue(
            @RequestParam(required = false) NiveauCours niveau,
            @RequestParam(required = false) UUID categorieId,
            @RequestParam(defaultValue = "0")  int page,
            @RequestParam(defaultValue = "12") int size) {
        Page<CoursResponse> result = catalogueUC.executer(niveau, categorieId, page, size);
        return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(result)));
    }

    /**
     * S4 — Page détail d'une formation.
     *
     * Retourne l'arbre COMPLET du cours :
     *   - Infos générales (titre, niveau, durée totale, nb apprenants, note)
     *   - Objectifs d'apprentissage (avec verbes d'action)
     *   - Débouchés avec chiffres FCFA (déclencheur émotionnel principal)
     *   - Programme complet : modules → leçons sommaires (pas le contenu)
     *   - Prochaines sessions disponibles (si formation avec formateur)
     *   - Avis vérifiés avec distribution des notes
     *   - Progression de l'apprenant connecté (si applicable)
     *
     * Pour obtenir le CONTENU d'une leçon :
     *   GET /api/v1/cours/{coursId}/modules/{moduleId}/lecons/{leconId}
     */
    @GetMapping("/{coursId}")
    @Operation(summary = "Détail complet d'une formation avec programme (S4)")
    public ResponseEntity<ApiResponse<CoursDetailResponse>> detail(
            @PathVariable UUID coursId,
            @AuthenticationPrincipal String userId) {
        UUID apprenantId = userId != null ? parseUUID(userId) : null;
        return ResponseEntity.ok(ApiResponse.ok(detailUC.executer(coursId, apprenantId)));
    }

    /**
     * S4 — Détail par slug (URL SEO-friendly).
     * Ex: GET /api/v1/cours/slug/developpement-web-java-spring
     */
    @GetMapping("/slug/{slug}")
    @Operation(summary = "Détail cours par slug SEO (S4)")
    public ResponseEntity<ApiResponse<CoursDetailResponse>> detailParSlug(
            @PathVariable String slug,
            @AuthenticationPrincipal String userId) {
        // TODO: ajouter findBySlug dans GetCoursDetailUseCase
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    private UUID parseUUID(String s) {
        try { return UUID.fromString(s); }
        catch (Exception e) { return null; }
    }
}
