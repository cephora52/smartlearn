package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;
import java.util.List;
import java.util.UUID;

/** S10 — Choix de créneaux horaires par l'apprenant */
public record ChoisirCreneauxRequest(
    @NotNull
    UUID sessionId,

    /** IDs des créneaux sélectionnés */
    @NotEmpty @Size(min = 1, max = 10)
    List<UUID> creneauIds
) {}
