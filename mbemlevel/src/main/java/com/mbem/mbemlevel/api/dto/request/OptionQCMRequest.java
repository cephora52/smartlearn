package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;

/**
 * Option d'une question QCM.
 * id   : "A", "B", "C" ou "D"
 * texte: Le libellé de l'option
 */
public record OptionQCMRequest(
    @NotBlank @Pattern(regexp = "[A-D]") String id,
    @NotBlank @Size(max = 500)           String texte
) {}
