package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public record FinalQuizRequest(
    @NotBlank(message = "Le titre de la formation ne peut pas être vide")
    String formationTitle,

    @NotEmpty(message = "La liste des leçons ne peut pas être vide")
    List<String> lessons
) {}
