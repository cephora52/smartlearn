package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;

/**
 * QCM attaché à une leçon.
 * Score minimum pour valider : 70% (configurable).
 * Pas de limite de tentatives.
 */
public record QCMRequest(

    @NotBlank @Size(max = 1000)
    String question,

    @NotEmpty @Size(min = 2, max = 4)
    @Valid
    List<OptionQCMRequest> options,

    /** Id de la bonne réponse : "A", "B", "C" ou "D" */
    @NotBlank @Pattern(regexp = "[A-D]")
    String bonneReponse,

    /**
     * Explication affichée après soumission.
     * Ex: "La réponse B est correcte car Spring Boot gère l'injection de dépendances."
     */
    @Size(max = 2000)
    String explication,

    /** Points accordés si bonne réponse. Défaut: 10 */
    @Min(1) @Max(100)
    int scorePoints

) {}
