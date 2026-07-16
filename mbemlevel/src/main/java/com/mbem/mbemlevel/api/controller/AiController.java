package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.request.ChatRequest;
import com.mbem.mbemlevel.api.dto.request.FinalQuizRequest;
import com.mbem.mbemlevel.api.dto.request.LessonQuestionRequest;
import com.mbem.mbemlevel.api.dto.response.ApiResponse;
import com.mbem.mbemlevel.api.dto.response.ChatResponse;
import com.mbem.mbemlevel.api.dto.response.FinalQuizResponse;
import com.mbem.mbemlevel.api.dto.response.LessonQuestionResponse;
import com.mbem.mbemlevel.application.usecase.ai.GeminiChatUseCase;
import com.mbem.mbemlevel.application.usecase.ai.GenererQuizFinalUseCase;
import com.mbem.mbemlevel.application.usecase.ai.PoserQuestionLeconUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.mbem.mbemlevel.application.usecase.ai.GenererResumeLeconUseCase;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/ai")
@Tag(name = "AI Chat", description = "Endpoints d'intégration IA avec Gemini")
@RequiredArgsConstructor
public class AiController {

    private final GeminiChatUseCase chatUseCase;
    private final GenererResumeLeconUseCase genererResumeLeconUC;
    private final PoserQuestionLeconUseCase poserQuestionLeconUC;
    private final GenererQuizFinalUseCase genererQuizFinalUC;

    @PostMapping("/chat")
    @Operation(summary = "Tester la connexion avec l'API Gemini")
    public ResponseEntity<ApiResponse<ChatResponse>> chat(@Valid @RequestBody ChatRequest request) {
        String answer = chatUseCase.executer(request.question());
        return ResponseEntity.ok(ApiResponse.ok(new ChatResponse(answer)));
    }

    @PostMapping("/lecons/{leconId}/resume")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Générer le résumé automatique d'une leçon")
    public ResponseEntity<ApiResponse<ChatResponse>> genererResumeLecon(
            @PathVariable UUID leconId,
            @AuthenticationPrincipal String userId) {
        UUID apprenantId = UUID.fromString(userId);
        String resume = genererResumeLeconUC.executer(leconId, apprenantId);
        return ResponseEntity.ok(ApiResponse.ok(new ChatResponse(resume)));
    }

    @PostMapping("/question")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Poser une question sur une leçon à l'IA")
    public ResponseEntity<ApiResponse<LessonQuestionResponse>> poserQuestion(
            @Valid @RequestBody LessonQuestionRequest request) {
        String answer = poserQuestionLeconUC.executer(request.lessonContent(), request.question());
        return ResponseEntity.ok(ApiResponse.ok(new LessonQuestionResponse(answer)));
    }

    @PostMapping("/final-quiz")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Générer le quiz final intelligent d'une formation")
    public ResponseEntity<ApiResponse<FinalQuizResponse>> finalQuiz(
            @Valid @RequestBody FinalQuizRequest request) {
        FinalQuizResponse quiz = genererQuizFinalUC.executer(request.formationTitle(), request.lessons());
        return ResponseEntity.ok(ApiResponse.ok(quiz));
    }
}
