package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.request.PostMessageRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.communaute.PostMessageUseCase;
import com.mbem.mbemlevel.application.port.out.CommunauteRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
/**
 * API Communauté — S12 (Q&R par cours).
 * GET  /api/v1/communaute/cours/{id}/questions
 * POST /api/v1/communaute/cours/{id}/messages
 * GET  /api/v1/communaute/messages/{id}/reponses
 */
@RestController
@RequestMapping("/api/v1/communaute")
@Tag(name="Communauté", description="Questions et réponses par cours")
@RequiredArgsConstructor
public class CommunauteController {
    private final PostMessageUseCase    postUC;
    private final CommunauteRepository  communauteRepo;

    @GetMapping("/cours/{coursId}/questions")
    @Operation(summary="Questions d'un cours (S12)")
    public ResponseEntity<ApiResponse<PageResponse<MessageResponse>>> questions(
            @PathVariable UUID coursId,
            @RequestParam(defaultValue="0") int page,
            @RequestParam(defaultValue="20") int size) {
        Page<MessageResponse> result = communauteRepo
            .findQuestions(coursId, PageRequest.of(page, size))
            .map(MessageResponse::from);
        return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(result)));
    }

    @PostMapping("/cours/{coursId}/messages")
    @Operation(summary="Poster une question ou réponse (S12)")
    public ResponseEntity<ApiResponse<MessageResponse>> poster(
            @PathVariable UUID coursId,
            @Valid @RequestBody PostMessageRequest req,
            @AuthenticationPrincipal String userId) {
        var msg = postUC.poster(coursId, UUID.fromString(userId),
            req.contenu(), req.parentId());
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.ok(MessageResponse.from(msg)));
    }

    @GetMapping("/messages/{parentId}/reponses")
    @Operation(summary="Réponses à une question")
    public ResponseEntity<ApiResponse<PageResponse<MessageResponse>>> reponses(
            @PathVariable UUID parentId,
            @RequestParam(defaultValue="0") int page,
            @RequestParam(defaultValue="20") int size) {
        Page<MessageResponse> result = communauteRepo
            .findReponses(parentId, PageRequest.of(page, size))
            .map(MessageResponse::from);
        return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(result)));
    }
}
