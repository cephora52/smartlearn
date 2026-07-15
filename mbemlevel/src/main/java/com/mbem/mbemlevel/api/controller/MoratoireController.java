package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.request.*;
import com.mbem.mbemlevel.api.dto.response.ApiResponse;
import com.mbem.mbemlevel.api.dto.response.AdminMoratoireResponse;
import com.mbem.mbemlevel.application.usecase.paiement.*;
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
 * Gestion des moratoires (délais de paiement) — S17
 *
 * POST  /api/v1/moratoires              → Apprenant demande un délai
 * GET   /api/v1/moratoires              → Admin consulte toutes les demandes
 * PATCH /api/v1/moratoires/{id}/decider → Admin accorde ou refuse
 */
@RestController
@RequestMapping("/api/v1/moratoires")
@Tag(name = "Moratoires", description = "Délais de paiement — S17")
@RequiredArgsConstructor
public class MoratoireController {

    private final DemanderMoratoireUseCase demanderUC;
    private final TraiterMoratoireUseCase  traiterUC;
    private final ObtenirTousMoratoiresUseCase obtenirTousUC;

    /** S17 — L'apprenant soumet une demande de délai */
    @PostMapping
    @PreAuthorize("hasRole('APPRENANT')")
    @Operation(summary = "Demander un moratoire (S17)")
    public ResponseEntity<ApiResponse<UUID>> demander(
            @Valid @RequestBody DemanderMoratoireRequest req,
            @AuthenticationPrincipal String userId) {
        UUID id = demanderUC.executer(req, UUID.fromString(userId));
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.ok(id,
                "Ta demande de délai a été soumise. L'équipe MbemNova te répondra rapidement."));
    }

    /** S17 — Admin consulte toutes les demandes de moratoire */
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary = "Consulter toutes les demandes de moratoire — admin (S17)")
    public ResponseEntity<ApiResponse<List<AdminMoratoireResponse>>> obtenirTous() {
        List<AdminMoratoireResponse> list = obtenirTousUC.executer();
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    /** S17 — Admin accorde ou refuse un moratoire */
    @PatchMapping("/{moratoireId}/decider")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary = "Traiter une demande de moratoire — admin (S17)")
    public ResponseEntity<ApiResponse<Void>> decider(
            @PathVariable UUID moratoireId,
            @Valid @RequestBody TraiterMoratoireRequest req,
            @AuthenticationPrincipal String adminId) {
        traiterUC.executer(moratoireId, req, UUID.fromString(adminId));
        String msg = "APPROUVE".equals(req.decision()) || "ACCORDE".equals(req.decision())
            ? "Moratoire accordé. Le plan de paiement a été mis à jour."
            : "Moratoire refusé. L'apprenant a été notifié.";
        return ResponseEntity.ok(ApiResponse.ok(msg));
    }
}
