package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.response.ApiResponse;
import com.mbem.mbemlevel.application.usecase.communaute.SignalerMessageUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

/**
 * Signalement de messages communauté — S12
 *
 * POST /api/v1/communaute/messages/{messageId}/signaler
 */
@RestController
@RequestMapping("/api/v1/communaute/messages")
@Tag(name = "Communauté", description = "Signalement de messages — S12")
@PreAuthorize("isAuthenticated()")
@RequiredArgsConstructor
public class SignalementController {

    private final SignalerMessageUseCase signalerUC;

    /** S12 — Signaler un message abusif */
    @PostMapping("/{messageId}/signaler")
    @Operation(summary = "Signaler un message abusif (S12)")
    public ResponseEntity<ApiResponse<Void>> signaler(
            @PathVariable UUID messageId,
            @AuthenticationPrincipal String userId) {
        signalerUC.executer(messageId, UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok("Message signalé. L'équipe MbemNova examinera ce contenu."));
    }
}
