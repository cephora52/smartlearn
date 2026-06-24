package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
public record ConnexionRequest(
    @NotBlank @Email String email,
    @NotBlank String motDePasse,
    boolean rememberMe
) {}
