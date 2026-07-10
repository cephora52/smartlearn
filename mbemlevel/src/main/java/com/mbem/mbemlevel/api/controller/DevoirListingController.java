package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.session.GetTableauBordDevoirsUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Listing des devoirs — S11 et S22
 *
 * GET /api/v1/devoirs/mes-devoirs                        → Mes devoirs (apprenant)
 * GET /api/v1/devoirs/sessions/{sessionId}/tableau-bord  → Suivi rendus (formateur)
 */
@RestController
@RequestMapping("/api/v1/devoirs")
@Tag(name = "Devoirs listing", description = "Listing devoirs — S11, S22")
@RequiredArgsConstructor
public class DevoirListingController {

    private final GetTableauBordDevoirsUseCase getTableauBordDevoirsUC;

    /**
     * S22 — Le formateur suit qui a rendu son devoir.
     * Retourne : soumis / pas encore soumis / en retard.
     */
    @GetMapping("/sessions/{sessionId}/tableau-bord")
    @PreAuthorize("hasAnyRole('FORMATEUR','ADMIN','SUPER_ADMIN')")
    @Operation(summary = "Tableau de bord des rendus pour une session (S22)")
    public ResponseEntity<ApiResponse<List<DevoirSuiviResponse>>> tableauBord(
            @PathVariable UUID sessionId) {
        List<DevoirSuiviResponse> suivi = getTableauBordDevoirsUC.executer(sessionId);
        return ResponseEntity.ok(ApiResponse.ok(suivi));
    }
}
