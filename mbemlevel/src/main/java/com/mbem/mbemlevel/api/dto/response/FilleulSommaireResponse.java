package com.mbem.mbemlevel.api.dto.response;

import java.time.LocalDateTime;

public record FilleulSommaireResponse(
    String        prenom,
    String        statut,          // EN_ATTENTE, ACTIF, RECOMPENSE_ACCORDEE
    LocalDateTime dateInscription,
    int           xpAccorde
) {}
