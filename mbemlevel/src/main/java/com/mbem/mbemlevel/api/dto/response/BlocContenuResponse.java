package com.mbem.mbemlevel.api.dto.response;

import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.cours.TypeBloc;
import com.mbem.mbemlevel.infrastructure.persistence.entity.BlocContenuJpaEntity;

/**
 * Réponse d'un bloc de contenu — seuls les champs pertinents au type sont inclus.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record BlocContenuResponse(
    UUID     id,
    TypeBloc typeBloc,
    int      ordre,

    // TEXTE_HTML
    String contenuHtml,

    // IMAGE
    String urlImage,
    String altImage,
    String legendeImage,

    // VIDEO
    String  urlVideo,
    Integer dureeVideoSec,

    // PDF
    String urlPdf,
    String nomPdf,

    // CODE
    String langageCode,
    String codeSource,

    // CALLOUT
    String typeCallout,
    String texteCallout
) {
    public static BlocContenuResponse from(BlocContenuJpaEntity e) {
        return new BlocContenuResponse(
            e.getId(), e.getTypeBloc(), e.getOrdre(),
            e.getContenuHtml(),
            e.getUrlImage(), e.getAltImage(), e.getLegendeImage(),
            e.getUrlVideo(), e.getDureeVideoSec(),
            e.getUrlPdf(), e.getNomPdf(),
            e.getLangageCode(), e.getCodeSource(),
            e.getTypeCallout(), e.getTexteCallout()
        );
    }
}
