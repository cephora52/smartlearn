package com.mbem.mbemlevel.api.dto.request;

import com.mbem.mbemlevel.domain.cours.TypeBloc;
import jakarta.validation.constraints.*;

/**
 * Représente un bloc de contenu dans une leçon.
 * Selon le type, certains champs sont obligatoires :
 *   TEXTE_HTML    → contenuHtml requis
 *   IMAGE         → urlImage requis
 *   VIDEO_*       → urlVideo requis
 *   PDF_EMBED     → urlPdf + nomPdf requis
 *   CODE          → langageCode + codeSource requis
 *   CALLOUT       → typeCallout + texteCallout requis
 */
public record BlocContenuRequest(

    @NotNull
    TypeBloc typeBloc,

    @Min(1)
    int ordre,

    // TEXTE_HTML
    String contenuHtml,

    // IMAGE
    String urlImage,
    String altImage,
    String legendeImage,

    // VIDEO
    String urlVideo,
    Integer dureeVideoSec,

    // PDF_EMBED
    String urlPdf,
    String nomPdf,

    // CODE
    String langageCode,
    String codeSource,

    // CALLOUT
    String typeCallout,     // INFO | ASTUCE | ATTENTION | IMPORTANT
    String texteCallout

) {}
