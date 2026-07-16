package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.application.usecase.ai.GeminiChatUseCase;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import com.mbem.mbemlevel.application.usecase.ai.GenererResumeLeconUseCase;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.web.method.annotation.AuthenticationPrincipalArgumentResolver;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("AiController — Unit Tests")
class AiControllerTest {

    private MockMvc mvc;

    @Mock
    private GeminiChatUseCase chatUseCase;

    @Mock
    private GenererResumeLeconUseCase genererResumeLeconUC;

    @Mock
    private com.mbem.mbemlevel.application.usecase.ai.PoserQuestionLeconUseCase poserQuestionLeconUC;

    @Mock
    private com.mbem.mbemlevel.application.usecase.ai.GenererQuizFinalUseCase genererQuizFinalUC;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.standaloneSetup(new AiController(chatUseCase, genererResumeLeconUC, poserQuestionLeconUC, genererQuizFinalUC))
            .setCustomArgumentResolvers(new AuthenticationPrincipalArgumentResolver())
            .build();
    }

    @Test
    @DisplayName("POST /api/v1/ai/chat avec question valide → retourne la réponse Gemini")
    void chat_avecQuestionValide_retourneReponse() throws Exception {
        when(chatUseCase.executer("Bonjour")).thenReturn("Salut! Je suis Gemini.");

        mvc.perform(post("/api/v1/ai/chat")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"question\": \"Bonjour\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.response").value("Salut! Je suis Gemini."));
    }

    @Test
    @DisplayName("POST /api/v1/ai/lecons/{leconId}/resume → retourne le résumé")
    void resume_avecLeconIdValide_retourneResume() throws Exception {
        UUID lid = UUID.randomUUID();
        when(genererResumeLeconUC.executer(any(), any())).thenReturn("Ceci est un résumé de la leçon.");

        org.springframework.security.core.context.SecurityContextHolder.getContext().setAuthentication(
            new UsernamePasswordAuthenticationToken("f1f1f1f1-f1f1-f1f1-f1f1-f1f1f1f1f1f1", "")
        );

        try {
            mvc.perform(post("/api/v1/ai/lecons/" + lid + "/resume")
                    .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.response").value("Ceci est un résumé de la leçon."));
        } finally {
            org.springframework.security.core.context.SecurityContextHolder.clearContext();
        }
    }
}
