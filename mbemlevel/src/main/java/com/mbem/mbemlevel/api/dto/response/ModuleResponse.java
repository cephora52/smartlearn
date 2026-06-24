package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;
import java.util.UUID;

/**
 * Module avec ses leçons (résumé — pas le contenu complet).
 * Pour le contenu complet d'une leçon : GET /api/v1/cours/lecons/{leconId}
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ModuleResponse(
    UUID              id,
    String            titre,
    String            description,
    int               ordre,
    int               xpBonus,
    boolean           estGratuit,
    boolean           estVerrouille,
    int               nbLecons,
    int               dureeTotaleMinutes,
    List<LeconSommaireResponse> lecons
) {}
