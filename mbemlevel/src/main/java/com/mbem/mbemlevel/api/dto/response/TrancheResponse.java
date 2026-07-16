package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDate;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record TrancheResponse(
    UUID id,
    UUID paiementId,
    String montant,
    LocalDate echeance,
    boolean estPayee,
    LocalDate datePaiement
) {}
