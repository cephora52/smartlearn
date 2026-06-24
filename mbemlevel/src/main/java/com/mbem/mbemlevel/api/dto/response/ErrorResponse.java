package com.mbem.mbemlevel.api.dto.response;
import java.time.LocalDateTime;
import java.util.List;
/** Réponse d'erreur HTTP détaillée. */
public record ErrorResponse(
    int status, String code, String message,
    List<String> details, LocalDateTime timestamp
) {}
