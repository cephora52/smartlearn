package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;

/** S4 — Laisser un avis vérifié sur un cours */
public record LaissserAvisRequest(
    @Min(1) @Max(5)
    int note,

    @Size(max = 2000)
    String commentaire
) {}
