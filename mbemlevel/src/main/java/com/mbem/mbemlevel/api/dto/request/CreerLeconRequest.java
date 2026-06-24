package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Création d'une leçon avec tout son contenu pédagogique.
 *
 * Une leçon contient :
 *  - Un titre et une description courte
 *  - Une liste ordonnée de BlocContenu (texte, image, vidéo, PDF, code, callout)
 *  - Un QCM optionnel (obligatoire si aQCM=true)
 *  - Des ressources téléchargeables optionnelles
 */
public record CreerLeconRequest(

    @NotBlank @Size(max = 200)
    String titre,

    @Size(max = 500)
    String descriptionCourte,

    @Min(1)
    int ordre,

    /** Durée estimée en minutes */
    @Min(1) @Max(600)
    int dureeMinutes,

    /** XP gagnés quand la leçon est validée. Défaut: 25 */
    @Min(0) @Max(500)
    int xpValeur,

    /**
     * Leçon accessible sans payer (avant le seuil).
     * Permet de montrer un aperçu gratuit.
     */
    boolean estPreview,

    /**
     * Contenu pédagogique ordonné de la leçon.
     * Peut contenir : texte, images, vidéos, PDFs, code, callouts.
     * Minimum 1 bloc.
     */
    @NotEmpty
    @Valid
    List<BlocContenuRequest> blocs,

    /**
     * QCM de la leçon (optionnel).
     * Si fourni, l'apprenant doit obtenir >= 70% pour valider la leçon.
     */
    @Valid
    QCMRequest qcm

) {
    public CreerLeconRequest {
        if (blocs == null) blocs = new ArrayList<>();
    }
    public boolean aQCM() { return qcm != null; }
}
