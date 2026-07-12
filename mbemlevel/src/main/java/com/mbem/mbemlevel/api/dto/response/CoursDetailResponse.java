package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import java.util.List;
import java.util.UUID;

/**
 * Réponse complète d'un cours — page détail de la formation.
 *
 * Structure identique à Udemy/OpenClassrooms :
 *  - Infos générales (titre, niveau, durée, nb apprenants, note)
 *  - Ce que tu vas apprendre (objectifs avec verbes d'action)
 *  - Débouchés avec chiffres FCFA (déclencheur émotionnel principal — S4)
 *  - Prérequis + public cible
 *  - Programme complet (modules → leçons sommaires)
 *  - Prochaines sessions disponibles
 *  - Avis vérifiés
 *  - Progression de l'apprenant (si connecté)
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record CoursDetailResponse(

    UUID        id,
    String      titre,
    String      descriptionCourte,
    String      descriptionLongue,
    NiveauCours niveau,
    String      langue,
    String      imageCouverture,
    String      imageCouvertureThumbnail,
    String      slug,
    String      formateurNom,
    String      categorieNom,

    // ── Stats ─────────────────────────────────────────────────────────────────
    int          nbModules,
    int          nbLecons,
    int          dureeTotaleMinutes,  // Pour afficher "15h de contenu"
    int          nbApprenants,
    Double       noteMoyenne,
    int          nbAvis,

    // ── Tarification ─────────────────────────────────────────────────────────
    long         prixFcfa,
    double       seuilPaiement,       // 0.30 = 30% gratuit

    // ── Contenu pédagogique ───────────────────────────────────────────────────

    /**
     * "Ce que tu vas apprendre" — liste de compétences avec verbes d'action.
     * Ex: ["Créer une API REST avec Spring Boot", "Déployer sur Railway", ...]
     * Affichées avec des ✓ verts — déclencheur de confiance (S4).
     */
    List<String>  objectifsApprentissage,

    /** Prérequis avant de commencer */
    String        prerequis,

    /** À qui s'adresse ce cours */
    String        publicCible,

    /**
     * Débouchés professionnels avec chiffres réels en FCFA.
     * PRINCIPAL déclencheur émotionnel d'inscription (S4) —
     * doit être affiché AU-DESSUS de la ligne de flottaison.
     * Ex: {"freelance":"300k-600k FCFA/mois","emploi":"Développeur Backend chez MTN"}
     */
    DebouchesInfo debouches,

    // ── Programme ─────────────────────────────────────────────────────────────

    /**
     * Programme complet — modules avec leurs leçons sommaires.
     * Les 2 premiers modules sont ouverts par défaut (accordéon).
     * Modules verrouillés visibles mais grisés.
     */
    List<ModuleResponse> modules,

    // ── Sessions (formation avec formateur) ───────────────────────────────────

    /** Prochaines sessions disponibles pour ce cours (S4, S9) */
    List<SessionSommaireResponse> prochainesSessions,

    // ── Avis ──────────────────────────────────────────────────────────────────

    /** Distribution des notes (pour l'histogramme étoiles) */
    DistributionNotes distributionNotes,

    /** Derniers avis vérifiés */
    List<AvisCoursResponse> avisRecents,

    // ── État apprenant (null si non connecté) ────────────────────────────────

    /** Progression de l'apprenant connecté (null si non connecté ou pas commencé) */
    ProgressionApprenanteResponse progression,

    /** Statut du cours */
    String statut  // BROUILLON | EN_REVISION | PUBLIE | ARCHIVE

) {
    /** Infos débouchés structurées */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record DebouchesInfo(
        String freelance,           // "300 000 – 600 000 FCFA/mois"
        String emploi,              // "Développeur Backend"
        String delaiPremierEmploi,  // "3-6 mois après certification"
        List<String> entreprises,   // ["MTN Cameroun","Orange Cameroun","startups"]
        String mention              // "Estimations basées sur les données du marché local"
    ) {}

    /** Distribution des notes 1 à 5 étoiles */
    public record DistributionNotes(
        int cinqEtoiles,
        int quatreEtoiles,
        int troisEtoiles,
        int deuxEtoiles,
        int uneEtoile
    ) {}

    /** Résumé de session pour la page détail cours */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record SessionSommaireResponse(
        UUID   id,
        String dateDebut,
        String dateFin,
        String modalite,          // PRESENTIEL | MEET
        String lieuOuLien,
        int    placesDisponibles,
        int    capaciteMax
    ) {}

    /** Progression de l'apprenant connecté sur ce cours */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record ProgressionApprenanteResponse(
        double  pourcentage,
        boolean estPaye,
        boolean seuilAtteint,
        int     xpGagne,
        String  derniereLeconTitre  // Pour "Reprendre à [Leçon X]"
    ) {}
}
