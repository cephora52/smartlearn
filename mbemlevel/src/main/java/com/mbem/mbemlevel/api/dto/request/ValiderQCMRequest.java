package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;
import java.util.UUID;

/** S6 — Soumission d'une réponse QCM par l'apprenant */
public record ValiderQCMRequest(
    @NotNull  UUID   leconId,
    @NotBlank @Pattern(regexp = "[A-D]") String reponse
) {}
