package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.request.*;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.admin.*;
import com.mbem.mbemlevel.application.usecase.admin.PublierCoursUseCase;
import com.mbem.mbemlevel.application.usecase.cours.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;
import java.util.UUID;

/**
 * API Cours Admin — Création et gestion des cours par formateur/admin.
 *
 * POST   /api/v1/admin/cours               → Créer un cours complet (S19)
 * POST   /api/v1/admin/cours/{id}/publier  → Publier le cours (admin)
 * GET    /api/v1/admin/cours/en-attente    → Cours en attente de publication
 * PUT    /api/v1/admin/cours/{id}/modules/{mId}/lecons/{lId}/blocs
 *                                          → Modifier les blocs d'une leçon
 * POST   /api/v1/admin/cours/{id}/ressources → Upload ressource cours
 */
@RestController
@RequestMapping("/api/v1/admin/cours")
@Tag(name = "Cours Admin", description = "Gestion LMS — création et édition des cours")
@PreAuthorize("hasAnyRole('FORMATEUR','ADMIN','SUPER_ADMIN')")
@RequiredArgsConstructor
public class CoursAdminController {

    private final CreerCoursCompletUseCase  creerCoursCompletUC;
    private final PublierCoursUseCase       publierUC;
    private final GetCoursEnAttenteUseCase  enAttenteUC;
    private final ModifierBlocsLeconUseCase modifierBlocsUC;

    /**
     * S19 — Créer un cours complet avec modules, leçons, blocs, QCM.
     * Le cours est créé en statut BROUILLON — non visible dans le catalogue.
     * L'admin doit le publier via POST /{id}/publier.
     */
    @PostMapping
    @Operation(summary = "Créer un cours complet (S19) — modules + leçons + contenu + QCM")
    public ResponseEntity<ApiResponse<UUID>> creerComplet(
            @Valid @RequestBody CreerCoursCompletRequest req,
            @AuthenticationPrincipal String userId) {
        UUID coursId = creerCoursCompletUC.executer(req, UUID.fromString(userId));
        return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(ApiResponse.ok(coursId, "Cours créé en brouillon. En attente de validation admin."));
    }

    /**
     * Modifier les blocs de contenu d'une leçon existante.
     * Remplace tous les blocs par la nouvelle liste.
     */
    @PutMapping("/{coursId}/lecons/{leconId}/blocs")
    @Operation(summary = "Mettre à jour les blocs de contenu d'une leçon")
    public ResponseEntity<ApiResponse<Void>> modifierBlocs(
            @PathVariable UUID coursId,
            @PathVariable UUID leconId,
            @Valid @RequestBody List<BlocContenuRequest> blocs,
            @AuthenticationPrincipal String userId) {
        modifierBlocsUC.executer(leconId, blocs, UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok("Contenu de la leçon mis à jour."));
    }

    /**
     * S19 — Publier un cours (admin uniquement).
     * Le cours devient visible dans le catalogue.
     */
    @PostMapping("/{coursId}/publier")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary = "Publier un cours — visible dans le catalogue (S19)")
    public ResponseEntity<ApiResponse<Void>> publier(
            @PathVariable UUID coursId,
            @AuthenticationPrincipal String adminId) {
        publierUC.executer(coursId, UUID.fromString(adminId));
        return ResponseEntity.ok(ApiResponse.ok("Cours publié dans le catalogue."));
    }

    /**
     * S19 — Lister les cours en attente de validation (admin).
     */
    @GetMapping("/en-attente")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary = "Cours en attente de publication (S19)")
    public ResponseEntity<ApiResponse<List<CoursResponse>>> enAttente() {
        return ResponseEntity.ok(ApiResponse.ok(enAttenteUC.executer()));
    }
}
