package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.UUID;

/**
 * Résumé d'une leçon (pour la liste dans un module).
 * Pas le contenu complet — juste les métadonnées.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record LeconSommaireResponse(
    UUID    id,
    String  titre,
    int     ordre,
    int     dureeMinutes,
    int     xpValeur,
    boolean estPreview,
    boolean aQCM,
    /** État de complétion pour l'apprenant connecté */
    Boolean estTerminee
) {}
