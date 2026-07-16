package com.mbem.mbemlevel.application.usecase.ai;

import com.mbem.mbemlevel.application.port.out.GeminiPort;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("PoserQuestionLecon — Use Case")
class PoserQuestionLeconUseCaseTest {

    @Mock private GeminiPort geminiPort;

    @InjectMocks private PoserQuestionLeconUseCase useCase;

    @Test
    @DisplayName("Poser une question → retourne la réponse de Gemini")
    void poserQuestion_retourneReponse() {
        String lessonContent = "Contenu de la leçon de test.";
        String question = "Quelle est la question ?";
        String expectedAnswer = "Ceci est la réponse de l'IA.";

        when(geminiPort.generateResponse(anyString())).thenReturn(expectedAnswer);

        String result = useCase.executer(lessonContent, question);

        assertThat(result).isEqualTo(expectedAnswer);
    }
}
