package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
public record NouveauMotDePasseRequest(
    @NotBlank String token,
    @NotBlank @Size(min=8,max=100) String nouveauMotDePasse
) {}
