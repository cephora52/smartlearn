package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
import java.util.UUID;
public record EnvoyerDevoirRequest(
    UUID moduleId,
    @NotBlank String titre,
    @NotBlank String consignes,
    @NotNull  LocalDateTime dateRemise,
    String lienRessources
) {}
