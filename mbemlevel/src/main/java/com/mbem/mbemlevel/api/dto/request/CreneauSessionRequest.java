package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;
import java.time.LocalTime;

/** Créneau récurrent d'une session */
public record CreneauSessionRequest(
    @NotBlank @Pattern(regexp = "LUNDI|MARDI|MERCREDI|JEUDI|VENDREDI|SAMEDI|DIMANCHE")
    String jourSemaine,

    @NotNull
    LocalTime heureDebut,

    @Min(30) @Max(480)
    int dureeMinutes,

    @Min(1) @Max(200)
    int capaciteMax
) {}
