package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
public record InscriptionRequest(
    @NotBlank @Size(min=2,max=50)
    @Pattern(regexp="^[\\p{L}\\s'-]+$", message="Caractères invalides")
    String prenom,
    @NotBlank @Email @Size(max=255)
    String email,
    @NotBlank @Size(min=8,max=100,message="8 caractères minimum")
    String motDePasse
) {}
