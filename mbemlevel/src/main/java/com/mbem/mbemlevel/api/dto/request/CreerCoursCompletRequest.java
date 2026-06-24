package com.mbem.mbemlevel.api.dto.request;

import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;
import java.util.UUID;

/**
 * Requête complète de création d'un cours — S19.
 *
 * Reproduit la structure d'un vrai LMS (W3Schools, OpenClassrooms, Udemy) :
 * Cours → Modules → Leçons → Blocs de contenu (texte/image/vidéo/PDF/code)
 *                         → QCM optionnel par leçon
 *
 * Le formateur remplit ce formulaire en 3 étapes (front) :
 *   Étape 1 : Informations générales (titre, description, niveau, prix...)
 *   Étape 2 : Structure des modules et leçons (drag & drop)
 *   Étape 3 : Contenu de chaque leçon (blocs, QCM)
 *
 * L'API reçoit le tout en un seul appel (ou on peut découper — voir endpoints).
 */
public record CreerCoursCompletRequest(

    // ── ÉTAPE 1 : Informations générales ─────────────────────────

    @NotBlank @Size(max = 200)
    String titre,

    /** Description courte pour les cartes du catalogue (max 500 chars) */
    @NotBlank @Size(max = 500)
    String descriptionCourte,

    /** Description longue pour la page détail — HTML autorisé (sanitisé) */
    @Size(max = 10000)
    String descriptionLongue,

    @NotNull
    NiveauCours niveau,

    UUID categorieId,

    /** Durée totale estimée en minutes — calculée automatiquement si omise */
    Integer dureeTotaleMinutes,

    /** URL image de bannière (MinIO) ou URL externe */
    @Size(max = 500)
    String imageCouverture,

    /**
     * Seuil (0.0 – 1.0) après lequel le paiement est demandé.
     * Ex: 0.30 = après 30% du cours. Défaut: 0.30
     */
    @DecimalMin("0.01") @DecimalMax("1.0")
    double seuilPaiement,

    @Min(0)
    long prixFcfa,

    /**
     * Ce que l'apprenant va apprendre.
     * Liste de phrases courtes avec verbe d'action.
     * Ex: ["Créer une API REST avec Spring Boot", "Déployer sur Railway"]
     */
    @Size(max = 20)
    List<@NotBlank @Size(max = 200) String> objectifsApprentissage,

    /** Prérequis nécessaires avant de commencer ce cours */
    @Size(max = 1000)
    String prerequis,

    /** À qui s'adresse ce cours */
    @Size(max = 500)
    String publicCible,

    // ── ÉTAPE 2 + 3 : Modules et leçons ─────────────────────────

    /**
     * Liste des modules du cours dans l'ordre.
     * Minimum 1 module, maximum 20.
     * Chaque module contient ses leçons avec leur contenu complet.
     */
    @NotEmpty @Size(min = 1, max = 20)
    @Valid
    List<CreerModuleRequest> modules

) {}
