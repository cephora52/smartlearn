package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.NotBlank;

public record LessonQuestionRequest(
    @NotBlank(message = "Le contenu de la leçon ne peut pas être vide")
    String lessonContent,

    @NotBlank(message = "La question ne peut pas être vide")
    String question
) {}
