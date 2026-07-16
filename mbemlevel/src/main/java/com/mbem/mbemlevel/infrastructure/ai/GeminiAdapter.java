package com.mbem.mbemlevel.infrastructure.ai;

import com.mbem.mbemlevel.application.port.out.GeminiPort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import java.util.List;

@Component
@Slf4j
public class GeminiAdapter implements GeminiPort {

    private final RestClient restClient;
    private final String apiKey;
    private final String model;

    public GeminiAdapter(
            @Value("${mbemnova.gemini.api.key:}") String apiKey,
            @Value("${mbemnova.gemini.api.model:gemini-3.5-flash}") String model) {
        this.restClient = RestClient.builder().build();
        this.apiKey = apiKey;
        this.model = model;
    }

    @Override
    public String generateResponse(String prompt) {
        if (apiKey == null || apiKey.isBlank()) {
            log.warn("[GEMINI] API key is missing. Returning placeholder message.");
            return "Clé API Gemini non configurée.";
        }

        var request = new GeminiRequest(List.of(
            new GeminiRequest.Content(List.of(
                new GeminiRequest.Part(prompt)
            ))
        ));

        try {
            var response = restClient.post()
                .uri("https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent?key=" + apiKey)
                .contentType(MediaType.APPLICATION_JSON)
                .body(request)
                .retrieve()
                .body(GeminiResponse.class);

            if (response != null && response.candidates() != null && !response.candidates().isEmpty()) {
                var candidate = response.candidates().get(0);
                if (candidate.content() != null && candidate.content().parts() != null && !candidate.content().parts().isEmpty()) {
                    return candidate.content().parts().get(0).text();
                }
            }
            return "Pas de réponse générée par Gemini.";
        } catch (Exception e) {
            log.error("[GEMINI] Erreur lors de l'appel à l'API Gemini: ", e);
            throw new RuntimeException("Erreur de communication avec Gemini: " + e.getMessage(), e);
        }
    }

    // Records internes pour le payload de l'API Gemini
    private record GeminiRequest(List<Content> contents) {
        private record Content(List<Part> parts) {}
        private record Part(String text) {}
    }

    private record GeminiResponse(List<Candidate> candidates) {
        private record Candidate(Content content) {}
        private record Content(List<Part> parts) {}
        private record Part(String text) {}
    }
}
