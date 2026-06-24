package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.request.*;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.session.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
/**
 * API Devoirs — S11 (publier, soumettre, corriger).
 */
@RestController
@RequestMapping("/api/v1/devoirs")
@Tag(name="Devoir", description="Gestion des devoirs et rendus")
@RequiredArgsConstructor
public class DevoirController {
    private final EnvoyerDevoirUseCase  envoyerUC;
    private final SoumettreRenduUseCase soumettreUC;
    private final CorrigerRenduUseCase  corrigerUC;

    /** POST /api/v1/devoirs/sessions/{sessionId} — Formateur publie un devoir (S11) */
    @PostMapping("/sessions/{sessionId}")
    @PreAuthorize("hasAnyRole('FORMATEUR','ADMIN','SUPER_ADMIN')")
    @Operation(summary="Publier un devoir (S11)")
    public ResponseEntity<ApiResponse<DevoirResponse>> publier(
            @PathVariable UUID sessionId,
            @Valid @RequestBody EnvoyerDevoirRequest req) {
        var d = envoyerUC.executer(sessionId, req.moduleId(), req.titre(),
            req.consignes(), req.dateRemise());
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.ok(DevoirResponse.from(d), "Devoir publié !"));
    }

    /** POST /api/v1/devoirs/soumettre — Apprenant soumet son rendu (S11) */
    @PostMapping("/soumettre")
    @Operation(summary="Soumettre un rendu (S11)")
    public ResponseEntity<ApiResponse<Void>> soumettre(
            @Valid @RequestBody SoumettreRenduRequest req,
            @AuthenticationPrincipal String userId) {
        soumettreUC.executer(req.devoirId(), UUID.fromString(userId),
            req.contenu(), req.lienFichier());
        return ResponseEntity.ok(ApiResponse.ok("Rendu soumis avec succès !"));
    }

    /** PATCH /api/v1/devoirs/rendus/{renduId}/corriger — Formateur corrige (S23) */
    @PatchMapping("/rendus/{renduId}/corriger")
    @PreAuthorize("hasAnyRole('FORMATEUR','ADMIN','SUPER_ADMIN')")
    @Operation(summary="Corriger un rendu (S23)")
    public ResponseEntity<ApiResponse<Void>> corriger(
            @PathVariable UUID renduId,
            @Valid @RequestBody CorrigerRenduRequest req) {
        corrigerUC.executer(renduId, req.note(), req.commentaire());
        return ResponseEntity.ok(ApiResponse.ok("Correction enregistrée."));
    }
}
