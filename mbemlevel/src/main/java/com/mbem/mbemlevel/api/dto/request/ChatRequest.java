package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.NotBlank;

public record ChatRequest(
    @NotBlank(message = "La question ne peut pas être vide")
    String question
) {}
