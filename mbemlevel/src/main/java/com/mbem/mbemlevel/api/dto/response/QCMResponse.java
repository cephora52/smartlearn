package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Réponse QCM — la bonne réponse N'EST PAS incluse (envoyée seulement après soumission).
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record QCMResponse(
    UUID               id,
    String             question,
    /** Options : [{id:"A", texte:"..."}, ...] */
    List<Map<String,String>> options,
    int                scorePoints,
    int                ordre
) {}
