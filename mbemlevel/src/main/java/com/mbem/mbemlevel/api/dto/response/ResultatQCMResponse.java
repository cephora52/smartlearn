package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;

/** Résultat après soumission d'un QCM — inclut la bonne réponse et l'explication */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ResultatQCMResponse(
    boolean estCorrect,
    int     scoreObtenu,
    String  bonneReponse,   // Révélée APRÈS soumission
    String  explication,    // "La bonne réponse est B car..."
    boolean leconValidee    // true si score >= 70%
) {}
