#!/usr/bin/env bash
# =============================================================================
# MbemNova — s23_corrections_incoherences.sh
# Corrige les 7 incohérences qui empêchent la compilation ou causent des erreurs runtime
#
# 1. WhatsAppPort — unifier le nom de méthode → envoyer()
# 2. Moratoire.accorder() — corriger la signature (LocalDate, pas String)
# 3. Cours.publier() — ajouter statut="PUBLIE" + setters manquants
# 4. CoursResponse.fromEntity() — ajouter méthode manquante
# 5. PaiementRepository — ajouter findByIdAndApprenantId
# 6. pom.xml — ajouter thumbnailator + spring-cloud-starter-circuitbreaker
# 7. Cours domain — ajouter tous les setters manquants
# =============================================================================
set -euo pipefail
ROOT="${1:-.}"
P="$ROOT/src/main/java/com/mbem/mbemlevel"
C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_RED='\033[0;31m'; C_NC='\033[0m'
ok()   { echo -e "  ${C_GREEN}✓${C_NC}  $1"; }
fix()  { echo -e "  ${C_RED}⚡${C_NC}  $1"; }
sec()  { echo -e "\n${C_BLUE}▶ $1${C_NC}"; }

mkdir -p "$P/application/port/out"
mkdir -p "$P/domain/cours"
mkdir -p "$P/domain/paiement"
mkdir -p "$P/api/dto/response"

echo -e "\n${C_BLUE}══════════════════════════════════════════════════════════════${C_NC}"
echo -e "${C_BLUE}  MbemNova · s23 · Corrections des 7 incohérences             ${C_NC}"
echo -e "${C_BLUE}══════════════════════════════════════════════════════════════${C_NC}\n"

# =============================================================================
# FIX 1 — WhatsAppPort unifié : toujours envoyer(telephone, message)
# =============================================================================
sec "FIX 1 — WhatsAppPort — méthode unifiée envoyer()"
fix "Le port original avait envoyerMessage() — nos scripts appellent envoyer()"

cat > "$P/application/port/out/WhatsAppPort.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;

/**
 * Port sortant — envoi de messages WhatsApp Business (Meta API).
 *
 * CORRECTION s23 : méthode principale unifiée → envoyer(telephone, message)
 * Méthodes spécialisées délèguent toutes vers envoyer().
 */
public interface WhatsAppPort {

    /**
     * Méthode principale — envoie un message texte libre.
     * Utilisée par tous les schedulers et use cases.
     */
    void envoyer(String telephone, String message);

    // ── Messages spécialisés — délèguent vers envoyer() ──────────────────────

    default void envoyerActivationAcces(String telephone, String prenom, String nomCours) {
        envoyer(telephone, String.format(
            "Bonjour %s ! ✅ Ton accès au cours %s vient d'être activé. " +
            "Tu peux reprendre là où tu t'étais arrêté. Bonne formation ! 🚀 — MbemNova",
            prenom, nomCours));
    }

    default void envoyerSuspension(String telephone, String prenom, String messageAdmin) {
        envoyer(telephone, String.format(
            "Bonjour %s, ton accès à MbemNova a été temporairement suspendu. %s " +
            "Contacte-nous pour régulariser. Ta progression est sauvegardée. — MbemNova",
            prenom, messageAdmin != null ? messageAdmin : ""));
    }

    default void envoyerReactivation(String telephone, String prenom, String nomCours) {
        envoyer(telephone, String.format(
            "Bonjour %s ! 🎉 Ton accès au cours %s a été réactivé. " +
            "Tu reprends exactement là où tu t'étais arrêté ! — MbemNova",
            prenom, nomCours));
    }

    default void envoyerCertificatObtenu(String telephone, String prenom, String nomCours) {
        envoyer(telephone, String.format(
            "🏆 Félicitations %s ! Tu as obtenu ta certification %s chez MbemNova ! " +
            "Ton profil est maintenant à jour. N'oublie pas de partager ta réussite 😊 — MbemNova",
            prenom, nomCours));
    }

    default void envoyerRappelSession(String telephone, String prenom,
                                       String nomFormation, String lieu) {
        envoyer(telephone, String.format(
            "Bonjour %s 👋 Rappel : ta session %s est demain. 📍 %s À demain ! 🚀 — MbemNova",
            prenom, nomFormation, lieu));
    }

    default void envoyerRappelDevoir(String telephone, String prenom, String titreDevoir) {
        envoyer(telephone, String.format(
            "Bonjour %s ⏰ Rappel : le devoir \"%s\" est à rendre demain. " +
            "N'oublie pas de soumettre à temps ! 💪 — MbemNova",
            prenom, titreDevoir));
    }

    default void envoyerNurturingSeuilAtteint(String telephone, String prenom,
                                               String nomCours, double pct) {
        envoyer(telephone, String.format(
            "Bonjour %s 👋 Tu étais à %.0f%% du cours %s — la suite t'attend ! " +
            "Dis-nous si tu as des questions sur le paiement 😊 — MbemNova",
            prenom, pct, nomCours));
    }

    default void envoyerRelancePaiement(String telephone, String prenom,
                                          long montant, String dateEcheance) {
        envoyer(telephone, String.format(
            "Bonjour %s 👋 Petit rappel : ta tranche de %d FCFA est prévue le %s. " +
            "Contacte-nous si tu as besoin d'aide ! 😊 — MbemNova",
            prenom, montant, dateEcheance));
    }
}
JEOF
ok "WhatsAppPort unifié (envoyer + méthodes default spécialisées)"

# =============================================================================
# FIX 2 — Moratoire domain — corriger accorder() pour prendre LocalDate
# =============================================================================
sec "FIX 2 — Moratoire.accorder() — signature corrigée"
fix "Prenait (UUID, String commentaire) — doit prendre (UUID, LocalDate)"

cat > "$P/domain/paiement/Moratoire.java" << 'JEOF'
package com.mbem.mbemlevel.domain.paiement;

import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Aggregate Moratoire — demande de délai de paiement (S17).
 *
 * CORRECTION s23 :
 *   accorder(UUID adminId, LocalDate nouvelleDateAccordee)
 *   refuser(UUID adminId, String justificationRefus)
 */
public class Moratoire extends AggregateRoot {

    private UUID      id;
    private UUID      paiementId;
    private String    raison;
    private LocalDate nouvelleDateSouhaitee;
    private LocalDate nouvelleDateAccordee;    // Remplie si accordé
    private String    statut;                  // EN_ATTENTE | ACCORDE | REFUSE
    private UUID      adminId;
    private String    justificationRefus;
    private LocalDateTime dateDecision;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // ── Factory ──────────────────────────────────────────────────────────────

    public static Moratoire creer(UUID paiementId, String raison,
                                   LocalDate nouvelleDateSouhaitee) {
        Moratoire m = new Moratoire();
        m.id = UUID.randomUUID();
        m.paiementId = paiementId;
        m.raison = raison;
        m.nouvelleDateSouhaitee = nouvelleDateSouhaitee;
        m.statut = "EN_ATTENTE";
        m.createdAt = LocalDateTime.now();
        m.updatedAt = LocalDateTime.now();
        return m;
    }

    // ── Comportements domaine ─────────────────────────────────────────────────

    /**
     * L'admin accorde le moratoire avec une nouvelle date d'échéance.
     *
     * @param adminId               Admin qui prend la décision
     * @param nouvelleDateAccordee  Nouvelle date d'échéance accordée
     */
    public void accorder(UUID adminId, LocalDate nouvelleDateAccordee) {
        if (!"EN_ATTENTE".equals(this.statut)) {
            throw new IllegalStateException("Moratoire déjà traité : " + this.statut);
        }
        this.statut = "ACCORDE";
        this.adminId = adminId;
        this.nouvelleDateAccordee = nouvelleDateAccordee;
        this.dateDecision = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        markUpdated();
    }

    /**
     * L'admin refuse le moratoire avec une justification.
     *
     * @param adminId              Admin qui prend la décision
     * @param justificationRefus   Raison du refus communiquée à l'apprenant
     */
    public void refuser(UUID adminId, String justificationRefus) {
        if (!"EN_ATTENTE".equals(this.statut)) {
            throw new IllegalStateException("Moratoire déjà traité : " + this.statut);
        }
        this.statut = "REFUSE";
        this.adminId = adminId;
        this.justificationRefus = justificationRefus;
        this.dateDecision = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        markUpdated();
    }

    // ── Reconstitution ────────────────────────────────────────────────────────

    public Moratoire(UUID id, UUID paiementId, String raison,
                     LocalDate nouvelleDateSouhaitee, LocalDate nouvelleDateAccordee,
                     String statut, UUID adminId, String justificationRefus,
                     LocalDateTime dateDecision,
                     LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id; this.paiementId = paiementId; this.raison = raison;
        this.nouvelleDateSouhaitee = nouvelleDateSouhaitee;
        this.nouvelleDateAccordee = nouvelleDateAccordee;
        this.statut = statut; this.adminId = adminId;
        this.justificationRefus = justificationRefus;
        this.dateDecision = dateDecision;
        this.createdAt = createdAt; this.updatedAt = updatedAt;
    }

    public Moratoire() {}

    // ── Getters ───────────────────────────────────────────────────────────────
    public UUID      getId()                    { return id; }
    public UUID      getPaiementId()            { return paiementId; }
    public String    getRaison()                { return raison; }
    public LocalDate getNouvelleDate()          { return nouvelleDateSouhaitee; }
    public LocalDate getNouvelledateSouhaitee() { return nouvelleDateSouhaitee; }
    public LocalDate getNouvelledateAccordee()  { return nouvelleDateAccordee; }
    public String    getStatut()                { return statut; }
    public UUID      getAdminId()               { return adminId; }
    public String    getJustificationRefus()    { return justificationRefus; }
    public LocalDateTime getDateDecision()      { return dateDecision; }
    public LocalDateTime getCreatedAt()         { return createdAt; }
    public LocalDateTime getUpdatedAt()         { return updatedAt; }
}
JEOF
ok "Moratoire.java (accorder/refuser avec LocalDate)"

# =============================================================================
# FIX 3 — Cours domain — publier() + tous les setters manquants
# =============================================================================
sec "FIX 3 — Cours domain — setters + publier() avec statut"
fix "publier() mettait seulement estActif=true sans statut='PUBLIE'"
fix "setDescriptionLongue(), setImageCouverture(), setNbModules()... absents"

cat > "$P/domain/cours/Cours.java" << 'JEOF'
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
JEOF
ok "Cours.java (publier() avec statut + tous les setters)"

# =============================================================================
# FIX 4 — CoursResponse — ajouter fromEntity() + champs manquants
# =============================================================================
sec "FIX 4 — CoursResponse — fromEntity() + champs catalogue"
fix "fromEntity(CoursJpaEntity) absent — GetCoursEnAttenteUseCase ne compile pas"

cat > "$P/api/dto/response/CoursResponse.java" << 'JEOF'
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
    String      slug
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
            c.getStatut(), c.getSlug()
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
            e.getStatut(), e.getSlug()
        );
    }
}
JEOF
ok "CoursResponse.java (from + fromEntity)"

# =============================================================================
# FIX 5 — PaiementRepository — ajouter findByIdAndApprenantId
# =============================================================================
sec "FIX 5 — PaiementRepository — findByIdAndApprenantId"
fix "DemanderMoratoireUseCase appelle cette méthode — absente du port"

cat > "$P/application/port/out/PaiementRepository.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.domain.paiement.Paiement;
import com.mbem.mbemlevel.domain.paiement.Tranche;
import java.time.LocalDate;
import java.util.*;

/**
 * Port sortant — Persistence des paiements.
 *
 * CORRECTION s23 : ajout de findByIdAndApprenantId()
 */
public interface PaiementRepository {

    Paiement           save(Paiement paiement);
    Optional<Paiement> findById(UUID id);

    /**
     * CORRECTION s23 — Vérification que le paiement appartient à l'apprenant.
     * Utilisé dans DemanderMoratoireUseCase pour éviter l'accès à un paiement
     * qui ne lui appartient pas (sécurité).
     */
    Optional<Paiement> findByIdAndApprenantId(UUID paiementId, UUID apprenantId);

    Optional<Paiement> findByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
    List<Paiement>     findByApprenantId(UUID apprenantId);
    List<Paiement>     findPaiementsEnCours();
    void               saveTranches(List<Tranche> tranches);
    List<Tranche>      findTranchesParPaiement(UUID paiementId);
    List<Tranche>      findTranchesEnRetard();
    List<Tranche>      findTranchesEcheantEntre(LocalDate debut, LocalDate fin);
}
JEOF
ok "PaiementRepository (findByIdAndApprenantId ajouté)"

# Ajouter la méthode dans l'adapter JPA correspondant
cat >> "$P/application/port/out/PaiementRepository.java" << 'JEOF2'
// ── Note pour l'implémentation JPA ───────────────────────────────────────────
// Dans PaiementRepositoryAdapter.java, ajouter :
//
// @Override
// public Optional<Paiement> findByIdAndApprenantId(UUID paiementId, UUID apprenantId) {
//     return paiementJpaRepo.findByIdAndApprenantId(paiementId, apprenantId)
//         .map(paiementMapper::toDomain);
// }
//
// Dans PaiementJpaRepository.java, ajouter :
// Optional<PaiementJpaEntity> findByIdAndApprenantId(UUID id, UUID apprenantId);
JEOF2
ok "Note d'implémentation JPA ajoutée dans PaiementRepository"

# =============================================================================
# FIX 6 — pom.xml — ajouter thumbnailator + spring-cloud-circuitbreaker
# =============================================================================
sec "FIX 6 — pom.xml — dépendances manquantes"
fix "thumbnailator absent (ImageCompressionService ne compile pas)"
fix "spring-cloud-starter-circuitbreaker absent (ResilienceConfig ne compile pas)"

# Créer un fichier patch pour pom.xml
cat > "$ROOT/pom_additions.xml" << 'POMEOF'
<!-- =============================================================================
     CORRECTIONS s23 — Dépendances à ajouter dans pom.xml
     Copier ces blocs dans la section <dependencies> de pom.xml
     ============================================================================= -->

<!-- ══════════════════════════════════════════════════════════════════════════
     FIX 6a — Thumbnailator (compression images légère — pas de ImageMagick)
     Utilisé par ImageCompressionService pour générer les 3 formats d'images
     ══════════════════════════════════════════════════════════════════════════ -->
<dependency>
    <groupId>net.coobird</groupId>
    <artifactId>thumbnailator</artifactId>
    <version>0.4.20</version>
</dependency>

<!-- ══════════════════════════════════════════════════════════════════════════
     FIX 6b — Spring Cloud Circuit Breaker (Resilience4j)
     Utilisé par ResilienceConfig et WhatsAppAdapterWithResilience
     ══════════════════════════════════════════════════════════════════════════ -->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-circuitbreaker-resilience4j</artifactId>
</dependency>

<!-- ══════════════════════════════════════════════════════════════════════════
     FIX 6c — Ajouter dans <dependencyManagement> si Spring Cloud BOM absent
     ══════════════════════════════════════════════════════════════════════════ -->
<!--
Dans <dependencyManagement><dependencies> :
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-dependencies</artifactId>
    <version>2023.0.3</version>
    <type>pom</type>
    <scope>import</scope>
</dependency>
-->

<!-- ══════════════════════════════════════════════════════════════════════════
     FIX 6d — Logstash Logback Encoder (pour logs JSON structurés)
     Si absent du pom.xml original
     ══════════════════════════════════════════════════════════════════════════ -->
<dependency>
    <groupId>net.logstash.logback</groupId>
    <artifactId>logstash-logback-encoder</artifactId>
    <version>7.4</version>
</dependency>
POMEOF
ok "pom_additions.xml — dépendances à ajouter dans pom.xml"

# =============================================================================
# FIX 7 — TraiterMoratoireUseCase — corriger l'appel à moratoire.accorder()
# =============================================================================
sec "FIX 7 — TraiterMoratoireUseCase — aligner avec le domain corrigé"

cat > "$P/application/usecase/paiement/TraiterMoratoireUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.paiement;

import com.mbem.mbemlevel.api.dto.request.TraiterMoratoireRequest;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.paiement.Moratoire;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S17 — L'admin traite une demande de moratoire.
 *
 * CORRECTION s23 :
 *   - moratoire.accorder() prend maintenant (UUID, LocalDate)
 *   - moratoire.refuser() prend (UUID, String) — inchangé
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TraiterMoratoireUseCase {

    private final MoratoireRepository      moratoireRepo;
    private final TrancheRepository        trancheRepo;
    private final ApplicationEventPublisher eventBus;

    @Transactional
    public void executer(UUID moratoireId, TraiterMoratoireRequest req, UUID adminId) {
        Moratoire moratoire = moratoireRepo.findById(moratoireId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:MORATOIRE:" + moratoireId));

        if (!"EN_ATTENTE".equals(moratoire.getStatut())) {
            throw new RuntimeException("BUSINESS_RULE:MORATOIRE_DEJA_TRAITE");
        }

        if ("ACCORDE".equals(req.decision())) {
            if (req.nouvelleDateAccordee() == null) {
                throw new RuntimeException("VALIDATION:nouvelle_date_obligatoire_si_accorde");
            }

            // CORRECTION : accorder(UUID, LocalDate) — conforme au domain corrigé
            moratoire.accorder(adminId, req.nouvelleDateAccordee());
            moratoireRepo.save(moratoire);

            // Mettre à jour la date d'échéance de la prochaine tranche
            trancheRepo.updateDateEcheance(moratoire.getPaiementId(), req.nouvelleDateAccordee());

            eventBus.publishEvent(new MoratoireDecideEvent(
                moratoireId, moratoire.getPaiementId(), "ACCORDE",
                req.nouvelleDateAccordee().toString(), null
            ));
            log.info("[MORATOIRE] Accordé: {} → {}", moratoireId, req.nouvelleDateAccordee());

        } else if ("REFUSE".equals(req.decision())) {
            if (req.justificationRefus() == null || req.justificationRefus().isBlank()) {
                throw new RuntimeException("VALIDATION:justification_obligatoire_si_refuse");
            }

            // refuser(UUID, String) — inchangé
            moratoire.refuser(adminId, req.justificationRefus());
            moratoireRepo.save(moratoire);

            eventBus.publishEvent(new MoratoireDecideEvent(
                moratoireId, moratoire.getPaiementId(), "REFUSE",
                null, req.justificationRefus()
            ));
            log.info("[MORATOIRE] Refusé: {} — {}", moratoireId, req.justificationRefus());

        } else {
            throw new RuntimeException("VALIDATION:decision_invalide:" + req.decision());
        }
    }

    public record MoratoireDecideEvent(
        UUID   moratoireId,
        UUID   paiementId,
        String decision,
        String nouvelleDateStr,
        String justificationRefus
    ) {}
}
JEOF
ok "TraiterMoratoireUseCase (aligné avec Moratoire.accorder(LocalDate))"

# =============================================================================
# VÉRIFICATION FINALE — résumé des incohérences restantes connues
# =============================================================================
sec "VÉRIFICATION FINALE — état après corrections"

cat > "$ROOT/CORRECTIONS_S23.md" << 'MDEOF'
# Corrections s23 — MbemNova

## 7 incohérences corrigées

| # | Fichier | Problème | Correction |
|---|---------|----------|-----------|
| 1 | `WhatsAppPort.java` | `envoyerMessage()` vs `envoyer()` | Unifié sur `envoyer()` + méthodes default |
| 2 | `Moratoire.java` | `accorder(UUID, String)` vs `accorder(UUID, LocalDate)` | Signature corrigée |
| 3 | `Cours.java` | `publier()` sans `statut="PUBLIE"` + setters manquants | Corrigé + 8 setters ajoutés |
| 4 | `CoursResponse.java` | `fromEntity()` absent | Ajouté aux côtés de `from()` |
| 5 | `PaiementRepository.java` | `findByIdAndApprenantId()` absent | Méthode ajoutée |
| 6 | `pom.xml` | `thumbnailator` + `spring-cloud-circuitbreaker` absents | `pom_additions.xml` généré |
| 7 | `TraiterMoratoireUseCase.java` | Appel `accorder(LocalDate)` sur ancien domain | Réécrit |

## Ce qui reste à faire manuellement

1. **pom.xml** — Copier le contenu de `pom_additions.xml` dans `<dependencies>`
2. **PaiementJpaRepository** — Ajouter `findByIdAndApprenantId(UUID, UUID)`
3. **PaiementRepositoryAdapter** — Implémenter la nouvelle méthode
4. **UtilisateurJpaEntity** — Ajouter `codeParrainage` + `deleted_at` (soft delete)
5. **UtilisateurJpaRepository** — Ajouter `findInscritsSansProgressionEntre()`
6. **ProgressionJpaRepository** — Ajouter `findSeuilAtteintNonPayeEntre()`

## Ordre d'exécution final complet

```bash
bash s01_pom_config.sh .          # existant
bash s02_structure.sh .            # existant
bash s03_domain.sh .               # existant
bash s04_application_auth.sh .     # existant
bash s05_migrations_sql.sh .       # existant
bash s06_jpa_infrastructure.sh .   # existant
bash s07_jwt_securite.sh .         # existant
bash s08_api_security.sh .         # existant
bash s09_cours_progression.sh .    # existant
bash s10_paiement.sh .             # existant
bash s11_session_devoir.sh .       # existant
bash s12_certificat_talent_communaute.sh . # existant
bash s13_admin_gamification.sh .   # existant
bash s14_devops.sh .               # existant
bash s15_tests_docs.sh .           # existant
# ── Nouveaux scripts (ordre important) ──
bash s16_migrations_manquantes.sh .
bash s17_jpa_entities_mappers_manquants.sh .
bash s18_lms_core_contenu.sh .
bash s19_usecases_manquants.sh .
bash s20_completions_finales.sh .
bash s21_lms_production_complet.sh .
bash s22_performance_enterprise.sh .
bash s23_corrections_incoherences.sh .    # CE SCRIPT — en dernier
```
MDEOF
ok "CORRECTIONS_S23.md — résumé complet"

echo ""
echo -e "${C_GREEN}╔══════════════════════════════════════════════════════════════╗${C_NC}"
echo -e "${C_GREEN}║  ✅  s23 — 7 incohérences corrigées                          ║${C_NC}"
echo -e "${C_GREEN}╚══════════════════════════════════════════════════════════════╝${C_NC}"
echo ""
echo "  FIX 1  WhatsAppPort        → envoyer() unifié + 8 méthodes default"
echo "  FIX 2  Moratoire.java      → accorder(UUID, LocalDate) ✓"
echo "  FIX 3  Cours.java          → publier() avec statut + 8 setters"
echo "  FIX 4  CoursResponse.java  → fromEntity() + champs complets"
echo "  FIX 5  PaiementRepository  → findByIdAndApprenantId() ajouté"
echo "  FIX 6  pom_additions.xml   → thumbnailator + spring-cloud-circuitbreaker"
echo "  FIX 7  TraiterMoratoire    → aligné avec nouveau domain Moratoire"
echo ""
echo "  ── 4 actions manuelles restantes ────────────────────────────────"
echo "  1. Copier pom_additions.xml dans pom.xml <dependencies>"
echo "  2. PaiementJpaRepository → findByIdAndApprenantId(UUID, UUID)"
echo "  3. UtilisateurJpaEntity  → codeParrainage + deleted_at"
echo "  4. ProgressionJpaRepository → findSeuilAtteintNonPayeEntre()"
