package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;
public record SoumettreRenduRequest(
    @NotNull UUID devoirId,
    String contenu,
    String lienFichier
) {}
