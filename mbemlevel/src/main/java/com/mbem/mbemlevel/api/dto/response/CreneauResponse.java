package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalTime;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record CreneauResponse(
    UUID      id,
    UUID      sessionId,
    String    jourSemaine,
    LocalTime heureDebut,
    int       dureeMinutes,
    int       capaciteMax,
    int       placesRestantes,
    Boolean   dejaCboisi    // Pour l'apprenant connecté
) {}
