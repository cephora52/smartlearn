package com.mbem.mbemlevel.application.usecase.ai;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mbem.mbemlevel.api.dto.response.FinalQuizResponse;
import com.mbem.mbemlevel.application.port.out.GeminiPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class GenererQuizFinalUseCase {

    private final GeminiPort geminiPort;
    private final ObjectMapper objectMapper;

    public FinalQuizResponse executer(String formationTitle, List<String> lessons) {
        StringBuilder lessonsContent = new StringBuilder();
        for (int i = 0; i < lessons.size(); i++) {
            lessonsContent.append("--- LEÇON ").append(i + 1).append(" ---\n")
                .append(lessons.get(i)).append("\n\n");
        }

        String prompt = "Tu es SmartLearn AI.\n\n"
            + "Tu dois créer un quiz final portant sur l'ensemble de la formation.\n"
            + "Le quiz doit évaluer les connaissances acquises tout au long de la formation.\n\n"
            + "Le quiz doit respecter exactement les règles suivantes :\n"
            + "- exactement 5 questions ;\n"
            + "- exactement 4 propositions par question ;\n"
            + "- une seule bonne réponse ;\n"
            + "- questions variées couvrant plusieurs leçons ;\n"
            + "- difficulté moyenne ;\n"
            + "- mauvaises réponses crédibles ;\n"
            + "- aucune ambiguïté ;\n"
            + "- retourner uniquement du JSON valide.\n\n"
            + "IMPORTANT: La valeur de \"correctAnswer\" doit être l'index à base 0 de la bonne réponse dans la liste des options (0 pour la 1ère option, 1 pour la 2ème, 2 pour la 3ème, et 3 pour la 4ème).\n\n"
            + "Le format attendu est :\n"
            + "{\n"
            + "  \"questions\":[\n"
            + "    {\n"
            + "      \"question\":\"...\",\n"
            + "      \"options\":[\n"
            + "        \"...\",\n"
            + "        \"...\",\n"
            + "        \"...\",\n"
            + "        \"...\"\n"
            + "      ],\n"
            + "      \"correctAnswer\":1,\n"
            + "      \"explanation\":\"...\"\n"
            + "    }\n"
            + "  ]\n"
            + "}\n\n"
            + "TITRE DE LA FORMATION : " + formationTitle + "\n\n"
            + "CONTENU DES LEÇONS :\n"
            + lessonsContent.toString();

        String rawResponse = geminiPort.generateResponse(prompt);

        // Nettoyer les balises Markdown si présentes
        String jsonText = rawResponse.trim();
        if (jsonText.startsWith("```")) {
            jsonText = jsonText.replaceAll("^```json\\s*", "");
            jsonText = jsonText.replaceAll("^```\\s*", "");
            jsonText = jsonText.replaceAll("\\s*```$", "");
        }
        jsonText = jsonText.trim();

        try {
            return objectMapper.readValue(jsonText, FinalQuizResponse.class);
        } catch (Exception e) {
            throw new RuntimeException("Erreur de formatage du quiz généré : " + e.getMessage(), e);
        }
    }
}
