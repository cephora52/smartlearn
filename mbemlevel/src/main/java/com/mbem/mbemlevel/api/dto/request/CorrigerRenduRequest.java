package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
public record CorrigerRenduRequest(
    @Min(0) @Max(20) int note,
    @NotBlank String commentaire
) {}
