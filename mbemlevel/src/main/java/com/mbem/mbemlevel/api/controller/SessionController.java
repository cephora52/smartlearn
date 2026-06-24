package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.request.InscrireSessionRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.session.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
/**
 * API Sessions — S09 (inscription), S10 (créneaux disponibles).
 */
@RestController
@RequestMapping("/api/v1/sessions")
@Tag(name="Session", description="Sessions de formation avec formateur")
@RequiredArgsConstructor
public class SessionController {
    private final InscrireApprenantSessionUseCase inscrireUC;
    private final GetSessionsDisponiblesUseCase   disponiblesUC;

    @GetMapping("/cours/{coursId}")
    @Operation(summary="Sessions disponibles pour un cours (S10)")
    public ResponseEntity<ApiResponse<List<SessionResponse>>> disponibles(@PathVariable UUID coursId) {
        List<SessionResponse> list = disponiblesUC.executer(coursId)
            .stream().map(SessionResponse::from).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    @PostMapping("/{sessionId}/inscrire")
    @Operation(summary="S'inscrire à une session (S09)")
    public ResponseEntity<ApiResponse<SessionResponse>> inscrire(
            @PathVariable UUID sessionId,
            @Valid @RequestBody InscrireSessionRequest req,
            @AuthenticationPrincipal String userId) {
        var session = inscrireUC.executer(sessionId, UUID.fromString(userId), req.coursId());
        return ResponseEntity.ok(ApiResponse.ok(SessionResponse.from(session),
            "Inscription confirmée ! Vous recevrez les détails par email."));
    }
}
