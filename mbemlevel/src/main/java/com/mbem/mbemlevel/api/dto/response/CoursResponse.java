package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.cours.Cours;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CoursJpaEntity;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * DTO de réponse cours — utilisé pour le catalogue et les listes admin.
 *
 * CORRECTION s23 :
 *   - Ajout fromEntity(CoursJpaEntity) pour GetCoursEnAttenteUseCase
 *   - Ajout champs manquants (thumbnail, nbLecons, dureeTotaleMinutes)
 *   - Cohérence from(Cours) avec les nouveaux champs du domain
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record CoursResponse(
    UUID        id,
    String      titre,
    String      descriptionCourte,
    NiveauCours niveau,
    String      langue,
    String      imageCouvertureThumbnail, // thumbnail 400px pour les cartes
    int         nbApprenants,
    Double      noteMoyenne,
    int         nbLecons,
    int         dureeTotaleMinutes,
    long        prixFcfa,
    BigDecimal  seuilPaiement,
    String      statut,
    String      slug,
    String      formateurNom,
    String      categorieNom
) {
    /**
     * Depuis le domain Cours — utilisé dans la plupart des use cases.
     */
    public static CoursResponse from(Cours c) {
        return new CoursResponse(
            c.getId(), c.getTitre(), c.getDescriptionCourte(),
            c.getNiveau(), c.getLangue(),
            c.getImageCouvertureThumbnail(),
            c.getNbApprenants(), c.getNoteMoyenne(),
            c.getNbLecons(), c.getDureeTotaleMinutes(),
            c.getPrixFcfa(), c.getSeuilPaiement(),
            c.getStatut(), c.getSlug(),
            null, null
        );
    }

    /**
     * CORRECTION s23 — Depuis l'entité JPA directement.
     * Utilisé dans GetCoursEnAttenteUseCase (lecture sans passer par le domain).
     */
    public static CoursResponse fromEntity(CoursJpaEntity e) {
        return new CoursResponse(
            e.getId(), e.getTitre(), e.getDescriptionCourte(),
            e.getNiveau(), e.getLangue(),
            e.getImageCouvertureThumbnail(),
            e.getNbApprenants(), e.getNoteMoyenne(),
            e.getNbLecons(), e.getDureeTotaleMinutes(),
            e.getPrixFcfa(), e.getSeuilPaiement(),
            e.getStatut(), e.getSlug(),
            null, null
        );
    }
}
