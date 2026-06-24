package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.request.ValiderQCMRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.progression.ValiderQCMUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

/**
 * Validation des QCM — S6
 *
 * POST /api/v1/qcm/lecons/{leconId}/valider → Soumettre une réponse QCM
 */
@RestController
@RequestMapping("/api/v1/qcm")
@Tag(name = "QCM", description = "Validation des QCM — S6")
@PreAuthorize("isAuthenticated()")
@RequiredArgsConstructor
public class QCMController {

    private final ValiderQCMUseCase validerUC;

    /**
     * S6 — Soumettre une réponse QCM.
     * La bonne réponse + explication sont retournées dans la réponse.
     * Pas de limite de tentatives.
     */
    @PostMapping("/lecons/{leconId}/valider")
    @Operation(summary = "Soumettre une réponse QCM (S6)")
    public ResponseEntity<ApiResponse<ResultatQCMResponse>> valider(
            @PathVariable UUID leconId,
            @Valid @RequestBody ValiderQCMRequest req,
            @AuthenticationPrincipal String userId) {
        ResultatQCMResponse resultat = validerUC.executer(
            leconId, req.reponse(), UUID.fromString(userId));
        String msg = resultat.estCorrect()
            ? "Bonne réponse ! +" + resultat.scoreObtenu() + " pts"
            : "Pas tout à fait — relis la leçon et réessaie. Tu peux retenter autant de fois que nécessaire.";
        return ResponseEntity.ok(ApiResponse.ok(resultat, msg));
    }
}
