package com.mbem.mbemlevel.infrastructure.persistence.repository.projection;

import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * Projection JPA légère pour le catalogue des cours.
 *
 * NE charge PAS :
 *   - description_longue (peut faire plusieurs Ko de HTML)
 *   - objectifs_apprentissage_json
 *   - debouches_json
 *   - prerequis, public_cible
 *   - image_couverture (original — on prend seulement le thumbnail)
 *
 * Résultat : 3x moins de data transférée depuis PostgreSQL vers Java.
 * Critique pour les requêtes de catalogue avec pagination.
 */
public interface CoursCatalogueProjection {
    UUID        getId();
    String      getTitre();
    String      getDescriptionCourte();
    NiveauCours getNiveau();
    String      getLangue();
    String      getImageCouvertureThumbnail(); // thumbnail 400px seulement
    int         getNbApprenants();
    Double      getNoteMoyenne();
    int         getNbLecons();
    int         getDureeTotaleMinutes();
    long        getPrixFcfa();
    BigDecimal  getSeuilPaiement();
}
