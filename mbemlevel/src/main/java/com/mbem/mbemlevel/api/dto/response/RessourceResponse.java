package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record RessourceResponse(
    UUID   id,
    String typeRessource,
    String nom,
    String urlStockage,
    Long   tailleOctets,
    String mimeType
) {}
