package com.mbem.mbemlevel.application.usecase.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mbem.mbemlevel.api.dto.response.FinalQuizResponse;
import com.mbem.mbemlevel.application.port.out.GeminiPort;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@DisplayName("GenererQuizFinal — Use Case")
class GenererQuizFinalUseCaseTest {

    @Mock private GeminiPort geminiPort;
    @Spy private ObjectMapper objectMapper = new ObjectMapper();

    @InjectMocks private GenererQuizFinalUseCase useCase;

    @Test
    @DisplayName("Générer le quiz final → retourne la structure de questions validée")
    void genererQuizFinal_retourneQuestions() {
        String mockResponse = "{\n"
            + "  \"questions\":[\n"
            + "    {\n"
            + "      \"question\":\"Quelle est la question ?\",\n"
            + "      \"options\":[\"A\", \"B\", \"C\", \"D\"],\n"
            + "      \"correctAnswer\":1,\n"
            + "      \"explanation\":\"Explication\"\n"
            + "    }\n"
            + "  ]\n"
            + "}";

        when(geminiPort.generateResponse(anyString())).thenReturn(mockResponse);

        FinalQuizResponse result = useCase.executer("Titre", List.of("Contenu leçon"));

        assertThat(result.questions()).hasSize(1);
        assertThat(result.questions().get(0).question()).isEqualTo("Quelle est la question ?");
        assertThat(result.questions().get(0).correctAnswer()).isEqualTo(1);
    }
}
