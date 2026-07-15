package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.response.ApiResponse;
import com.mbem.mbemlevel.api.dto.response.DrawResponse;
import com.mbem.mbemlevel.api.dto.response.TicketResponse;
import com.mbem.mbemlevel.application.usecase.gamification.ObtenirTirageAuSortUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/tirage")
@Tag(name = "Tirage au sort", description = "Consultation et participation aux tirages au sort mensuels")
@PreAuthorize("hasRole('APPRENANT')")
@RequiredArgsConstructor
public class TirageController {

    private final ObtenirTirageAuSortUseCase obtenirTirageUC;

    @GetMapping
    @Operation(summary = "Obtenir le dernier tirage au sort (S24)")
    public ResponseEntity<ApiResponse<DrawResponse>> getLatest() {
        var drawOpt = obtenirTirageUC.executer();
        return ResponseEntity.ok(ApiResponse.ok(drawOpt.orElse(null)));
    }

    @PostMapping
    @Operation(summary = "Acheter/S'inscrire à un tirage au sort (Simulation)")
    public ResponseEntity<ApiResponse<TicketResponse>> acheterTicket(@RequestBody Map<String, String> body) {
        String drawIdStr = body.get("drawId");
        if (drawIdStr == null || drawIdStr.isBlank()) {
            drawIdStr = UUID.randomUUID().toString();
        }
        
        TicketResponse response = new TicketResponse(
            "ticket-" + UUID.randomUUID().toString().substring(0, 8),
            drawIdStr,
            "MB-" + (1000 + new java.util.Random().nextInt(9000)),
            java.time.LocalDateTime.now().toString()
        );
        return ResponseEntity.ok(ApiResponse.ok(response, "Ticket acheté !"));
    }
}
