package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record AvisCoursResponse(
    UUID          id,
    UUID          apprenantId,
    int           note,
    String        commentaire,
    LocalDateTime createdAt
) {}
