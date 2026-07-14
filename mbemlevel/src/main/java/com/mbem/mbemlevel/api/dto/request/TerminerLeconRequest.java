package com.mbem.mbemlevel.api.dto.request;

import java.util.UUID;

import jakarta.validation.constraints.*;

public record TerminerLeconRequest(
        @NotNull UUID leconId,
        @Min(0) int nbLeconsTotales,
        @Min(0) int nbLeconsTerminees,
        @Min(0) int xpLecon,
        String nomCours,
        String telephone) {
    public TerminerLeconRequest {
        java.util.Objects.requireNonNull(leconId);
    }
}
