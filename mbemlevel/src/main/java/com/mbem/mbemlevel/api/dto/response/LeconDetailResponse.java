package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;
import java.util.UUID;

/**
 * Réponse complète d'une leçon avec tout son contenu pédagogique.
 * Retournée quand l'apprenant ouvre une leçon.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record LeconDetailResponse(
    UUID                      id,
    UUID                      coursId,
    String                    titre,
    String                    descriptionCourte,
    int                       ordre,
    int                       dureeMinutes,
    int                       xpValeur,
    boolean                   estPreview,
    boolean                   aQCM,
    /** Blocs de contenu dans l'ordre d'affichage */
    List<BlocContenuResponse> blocs,
    /** QCM de la leçon (null si pas de QCM) */
    QCMResponse               qcm,
    /** Ressources téléchargeables de la leçon */
    List<RessourceResponse>   ressources
) {}
