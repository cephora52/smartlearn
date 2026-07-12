package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CoursJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.projection.CoursCatalogueProjection;

import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CoursJpaRepository extends JpaRepository<CoursJpaEntity, UUID> {

    /** Catalogue public filtré — S4 */
    @Query("SELECT c FROM CoursJpaEntity c WHERE c.statut = 'PUBLIE' " +
           "AND (:niveau IS NULL OR c.niveau = :niveau) " +
           "AND (:categorieId IS NULL OR c.categorieId = :categorieId) " +
           "ORDER BY c.nbApprenants DESC")
    Page<CoursJpaEntity> findCatalogue(
        @Param("niveau")      NiveauCours niveau,
        @Param("categorieId") UUID categorieId,
        Pageable pageable
    );

    Optional<CoursJpaEntity> findBySlug(String slug);
    boolean existsBySlug(String slug);
    boolean existsByTitreAndFormateurId(String titre, UUID formateurId);
    List<CoursJpaEntity> findByFormateurIdAndTitre(UUID formateurId, String titre);

    /** S19 — Cours en attente de publication (admin) */
    List<CoursJpaEntity> findByStatutIn(List<String> statuts);

    /** Cours du formateur */
    List<CoursJpaEntity> findByFormateurId(UUID formateurId);


    @Query("SELECT c.id as id, c.titre as titre, c.descriptionCourte as descriptionCourte, " +
       "c.niveau as niveau, c.langue as langue, " +
       "c.imageCouvertureThumbnail as imageCouvertureThumbnail, " +
       "c.nbApprenants as nbApprenants, c.noteMoyenne as noteMoyenne, " +
       "c.nbLecons as nbLecons, c.dureeTotaleMinutes as dureeTotaleMinutes, " +
       "c.prixFcfa as prixFcfa, c.seuilPaiement as seuilPaiement, c.slug as slug, " +
       "u.prenom as formateurPrenom, u.nom as formateurNom, " +
       "cat.nom as categorieNom " +
       "FROM CoursJpaEntity c " +
       "LEFT JOIN UtilisateurJpaEntity u ON c.formateurId = u.id " +
       "LEFT JOIN CategorieJpaEntity cat ON c.categorieId = cat.id " +
       "WHERE c.statut = 'PUBLIE' " +
       "AND (:niveau IS NULL OR c.niveau = :niveau) " +
       "AND (:categorieId IS NULL OR c.categorieId = :categorieId)")
Page<CoursCatalogueProjection> findCatalogueProjection(
    @Param("niveau")      NiveauCours niveau,
    @Param("categorieId") UUID categorieId,
    Pageable pageable
);
}
// ── Projection légère pour le catalogue (ajouter dans CoursJpaRepository) ────
/*
    @Query("SELECT c.id as id, c.titre as titre, c.descriptionCourte as descriptionCourte, " +
           "c.niveau as niveau, c.langue as langue, " +
           "c.imageCouvertureThumbnail as imageCouvertureThumbnail, " +
           "c.nbApprenants as nbApprenants, c.noteMoyenne as noteMoyenne, " +
           "c.nbLecons as nbLecons, c.dureeTotaleMinutes as dureeTotaleMinutes, " +
           "c.prixFcfa as prixFcfa, c.seuilPaiement as seuilPaiement " +
           "FROM CoursJpaEntity c WHERE c.statut = 'PUBLIE' " +
           "AND (:niveau IS NULL OR c.niveau = :niveau) " +
           "AND (:categorieId IS NULL OR c.categorieId = :categorieId)")
    Page<CoursCatalogueProjection> findCatalogueProjection(
        @Param("niveau")      NiveauCours niveau,
        @Param("categorieId") UUID categorieId,
        Pageable pageable
    );
*/
