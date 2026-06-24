package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/** Requête pour renvoyer le lien de confirmation email. */
public record ResendConfirmationRequest(
    @NotBlank @Email String email
) {}