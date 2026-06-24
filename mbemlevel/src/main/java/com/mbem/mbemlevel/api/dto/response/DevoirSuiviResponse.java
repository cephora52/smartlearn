package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import java.util.UUID;

/** S22 — Suivi des rendus d'un devoir pour le formateur */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record DevoirSuiviResponse(
    UUID          devoirId,
    String        titre,
    LocalDateTime dateLimite,
    int           nbRendusTotal,
    int           nbATemps,
    int           nbEnRetard
) {}
