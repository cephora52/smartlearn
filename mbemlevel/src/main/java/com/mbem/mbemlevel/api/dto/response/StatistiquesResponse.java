package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record StatistiquesResponse(
    long totalApprenants,
    long apprenantsActifs,
    long paiementsEnAttente,
    long paiementsEnRetard,
    long revenusTotal,
    String revenus
) {}
