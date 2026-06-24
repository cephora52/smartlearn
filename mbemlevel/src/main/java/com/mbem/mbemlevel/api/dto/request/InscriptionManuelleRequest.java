package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
public record InscriptionManuelleRequest(
    @NotBlank @Size(min=2,max=50) String prenom,
    @NotBlank @Email String email,
    @NotBlank @Size(min=8) String motDePasse
) {}
