package com.mbem.mbemlevel.domain.cours;

import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Aggregate Cours — cœur du LMS.
 *
 * CORRECTION s23 :
 *   - publier() met maintenant statut="PUBLIE" ET estActif=true
 *   - Ajout de tous les setters manquants utilisés dans CreerCoursCompletUseCase
 */
public class Cours extends AggregateRoot {

    private UUID        id;
    private String      titre;
    private String      descriptionCourte;
    private String      descriptionLongue;
    private NiveauCours niveau;
    private UUID        categorieId;
    private UUID        formateurId;
    private String      slug;
    private String      imageCouverture;
    private String      imageCouvertureThumbnail;
    private String      langue;
    private List<String> objectifsApprentissage;
    private String      prerequis;
    private String      publicCible;
    private String      debouchesJson;
    private int         nbModules;
    private int         nbLecons;
    private int         dureeTotaleMinutes;
    private int         nbApprenants;
    private Double      noteMoyenne;
    private int         nbAvis;
    private BigDecimal  seuilPaiement;
    private long        prixFcfa;
    private String      statut;      // BROUILLON | EN_REVISION | PUBLIE | ARCHIVE
    private boolean     estActif;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // ── Factory de création ──────────────────────────────────────────────────

    public static Cours creer(String titre, String descriptionCourte,
                               NiveauCours niveau, UUID categorieId,
                               UUID formateurId, double seuilPaiement, long prixFcfa) {
        Cours c = new Cours();
        c.id = UUID.randomUUID();
        c.titre = titre;
        c.descriptionCourte = descriptionCourte;
        c.niveau = niveau;
        c.categorieId = categorieId;
        c.formateurId = formateurId;
        c.seuilPaiement = BigDecimal.valueOf(seuilPaiement);
        c.prixFcfa = prixFcfa;
        c.statut = "BROUILLON";
        c.estActif = false;
        c.langue = "fr";
        c.nbModules = 0;
        c.nbLecons = 0;
        c.dureeTotaleMinutes = 0;
        c.nbApprenants = 0;
        c.nbAvis = 0;
        c.slug = genererSlug(titre);
        c.createdAt = LocalDateTime.now();
        c.updatedAt = LocalDateTime.now();
        return c;
    }

    // ── Comportements domaine ─────────────────────────────────────────────────

    /**
     * CORRECTION : met statut="PUBLIE" ET estActif=true.
     * Déclenche l'invalidation du cache catalogue.
     */
    public void publier() {
        if ("PUBLIE".equals(this.statut)) {
            throw new IllegalStateException("Cours déjà publié.");
        }
        this.statut  = "PUBLIE";
        this.estActif = true;
        this.updatedAt = LocalDateTime.now();
        markUpdated();
    }

    public void soumettrePourRevision() {
        if (!"BROUILLON".equals(this.statut)) {
            throw new IllegalStateException("Seul un brouillon peut être soumis pour révision.");
        }
        this.statut = "EN_REVISION";
        this.updatedAt = LocalDateTime.now();
        markUpdated();
    }

    public void archiver() {
        this.statut  = "ARCHIVE";
        this.estActif = false;
        this.updatedAt = LocalDateTime.now();
        markUpdated();
    }

    public void incrementerNbApprenants() {
        this.nbApprenants++;
        this.updatedAt = LocalDateTime.now();
        markUpdated();
    }

    // ── Setters (utilisés dans CreerCoursCompletUseCase) ─────────────────────

    public void setDescriptionLongue(String descriptionLongue) {
        this.descriptionLongue = descriptionLongue;
        this.updatedAt = LocalDateTime.now();
    }

    public void setImageCouverture(String urlOriginal) {
        this.imageCouverture = urlOriginal;
        this.updatedAt = LocalDateTime.now();
    }

    public void setImageCouvertureThumbnail(String urlThumbnail) {
        this.imageCouvertureThumbnail = urlThumbnail;
        this.updatedAt = LocalDateTime.now();
    }

    public void setObjectifsApprentissage(List<String> objectifs) {
        this.objectifsApprentissage = objectifs;
        this.updatedAt = LocalDateTime.now();
    }

    /** S19 — prérequis + public cible renseignés en une seule opération */
    public void setPrerequisEtPublicCible(String prerequis, String publicCible) {
        this.prerequis = prerequis;
        this.publicCible = publicCible;
        this.updatedAt = LocalDateTime.now();
    }

    public void setNbModules(int nbModules) {
        this.nbModules = nbModules;
        this.updatedAt = LocalDateTime.now();
    }

    public void setDureeTotaleMinutes(int duree) {
        this.dureeTotaleMinutes = duree;
        this.updatedAt = LocalDateTime.now();
    }

    public void setNbLecons(int nbLecons) {
        this.nbLecons = nbLecons;
        this.updatedAt = LocalDateTime.now();
    }

    public void setDebouchesJson(String json) {
        this.debouchesJson = json;
        this.updatedAt = LocalDateTime.now();
    }

    public void setNoteMoyenne(Double note, int nbAvis) {
        this.noteMoyenne = note;
        this.nbAvis = nbAvis;
        this.updatedAt = LocalDateTime.now();
    }

    // ── Getters ───────────────────────────────────────────────────────────────
    public UUID        getId()                    { return id; }
    public String      getTitre()                 { return titre; }
    public String      getDescriptionCourte()     { return descriptionCourte; }
    public String      getDescriptionLongue()     { return descriptionLongue; }
    public NiveauCours getNiveau()                { return niveau; }
    public UUID        getCategorieId()           { return categorieId; }
    public UUID        getFormateurId()           { return formateurId; }
    public String      getSlug()                  { return slug; }
    public String      getImageCouverture()       { return imageCouverture; }
    public String      getImageCouvertureThumbnail() { return imageCouvertureThumbnail; }
    public String      getLangue()                { return langue; }
    public List<String> getObjectifsApprentissage() { return objectifsApprentissage; }
    public String      getPrerequis()             { return prerequis; }
    public String      getPublicCible()           { return publicCible; }
    public String      getDebouchesJson()         { return debouchesJson; }
    public int         getNbModules()             { return nbModules; }
    public int         getNbLecons()              { return nbLecons; }
    public int         getDureeTotaleMinutes()    { return dureeTotaleMinutes; }
    public int         getNbApprenants()          { return nbApprenants; }
    public Double      getNoteMoyenne()           { return noteMoyenne; }
    public int         getNbAvis()                { return nbAvis; }
    public BigDecimal  getSeuilPaiement()         { return seuilPaiement; }
    public long        getPrixFcfa()              { return prixFcfa; }
    public String      getStatut()                { return statut; }
    public boolean     isEstActif()               { return estActif; }
    public LocalDateTime getCreatedAt()           { return createdAt; }
    public LocalDateTime getUpdatedAt()           { return updatedAt; }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private static String genererSlug(String titre) {
        if (titre == null) return UUID.randomUUID().toString();
        return titre.toLowerCase()
            .replaceAll("[àáâãäå]", "a").replaceAll("[èéêë]", "e")
            .replaceAll("[ìíîï]", "i").replaceAll("[òóôõö]", "o")
            .replaceAll("[ùúûü]", "u").replaceAll("[ç]", "c")
            .replaceAll("[^a-z0-9\\s-]", "")
            .replaceAll("\\s+", "-")
            .replaceAll("-+", "-")
            .replaceAll("^-|-$", "");
    }

    /** Constructeur de reconstitution depuis la persistence */
    public Cours(UUID id, String titre, String descriptionCourte, String descriptionLongue,
                 NiveauCours niveau, UUID categorieId, UUID formateurId, String slug,
                 String imageCouverture, String imageCouvertureThumbnail, String langue,
                 int nbModules, int nbLecons, int dureeTotaleMinutes,
                 int nbApprenants, Double noteMoyenne, int nbAvis,
                 BigDecimal seuilPaiement, long prixFcfa, String statut, boolean estActif,
                 LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id; this.titre = titre;
        this.descriptionCourte = descriptionCourte;
        this.descriptionLongue = descriptionLongue;
        this.niveau = niveau; this.categorieId = categorieId;
        this.formateurId = formateurId; this.slug = slug;
        this.imageCouverture = imageCouverture;
        this.imageCouvertureThumbnail = imageCouvertureThumbnail;
        this.langue = langue; this.nbModules = nbModules;
        this.nbLecons = nbLecons; this.dureeTotaleMinutes = dureeTotaleMinutes;
        this.nbApprenants = nbApprenants; this.noteMoyenne = noteMoyenne;
        this.nbAvis = nbAvis; this.seuilPaiement = seuilPaiement;
        this.prixFcfa = prixFcfa; this.statut = statut; this.estActif = estActif;
        this.createdAt = createdAt; this.updatedAt = updatedAt;
    }

    public Cours() {}
}
