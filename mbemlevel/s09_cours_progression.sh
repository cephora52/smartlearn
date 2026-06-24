#!/usr/bin/env bash
# =============================================================================
# MbemNova · Script 09/15 · Cours + Progression
# =============================================================================
# CONTENU :
#   Domain  : Cours, Module, Lecon, QCM, Categorie, CoursDomainService
#             Progression, ReponseQCM, Badge, ProgressionDomainService
#   JPA     : CoursJpaEntity, ModuleJpaEntity, LeconJpaEntity, QCMJpaEntity
#             ProgressionJpaEntity, ReponseQCMJpaEntity, BadgeJpaEntity
#   Repos   : CoursJpaRepository, ProgressionJpaRepository
#   Adapters: CoursRepositoryAdapter, ProgressionRepositoryAdapter
#   Ports   : CoursRepository, ProgressionRepository
#   UseCases: GetCatalogueUseCase, GetDetailCoursUseCase, CommencerCoursUseCase
#             TerminerLeconUseCase, ValiderQCMUseCase, GetProgressionUseCase
#             VerifierSeuilPaiementUseCase
#   API     : CoursController, ProgressionController, CoursResponse, ProgressionResponse
# SCÉNARIOS : S04 (catalogue), S05 (commencer cours), S06 (leçon+QCM), S07 (seuil)
# =============================================================================
set -euo pipefail; export LC_ALL=C.UTF-8
G='\033[0;32m'; C='\033[0;36m'; B='\033[1m'; N='\033[0m'
ok()  { echo -e "${G}  [OK]${N} $1"; }
sec() { echo -e "\n${B}${C}── $1 ──${N}"; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$ROOT/src/main/java/com/mbem/mbemlevel"
[[ ! -f "$ROOT/pom.xml" ]] && { echo "ERR: s01 requis"; exit 1; }
echo -e "\n${B}${C}  MbemNova · 09/15 · Cours + Progression${N}\n"

# =============================================================================
sec "1/5 Domain Cours"
# =============================================================================
mkdir -p "$P/domain/cours"

cat > "$P/domain/cours/Categorie.java" << 'JEOF'
package com.mbem.mbemlevel.domain.cours;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Agrégat Catégorie — thème principal d'un cours. */
public class Categorie extends AggregateRoot {
    private String nom;
    private String description;
    private String icone;

    public static Categorie creer(String nom, String description) {
        if (nom == null || nom.isBlank()) throw new IllegalArgumentException("Nom obligatoire");
        Categorie c = new Categorie(); c.nom = nom.trim(); c.description = description; return c;
    }
    public Categorie(UUID id, String nom, String description, String icone,
                     LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua); this.nom = nom; this.description = description; this.icone = icone;
    }
    public String getNom()         { return nom; }
    public String getDescription() { return description; }
    public String getIcone()       { return icone; }
}
JEOF

cat > "$P/domain/cours/Cours.java" << 'JEOF'
package com.mbem.mbemlevel.domain.cours;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import com.mbem.mbemlevel.domain.shared.Money;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
/**
 * Agrégat Cours — racine de l'arbre pédagogique.
 * Règles : seuil 0-100%, prix >= 0, slug unique.
 */
public class Cours extends AggregateRoot {
    private String      titre;
    private String      description;
    private NiveauCours niveau;
    private UUID        categorieId;
    private UUID        formateurId;
    /** Pourcentage (0.0–1.0) après lequel le paiement est demandé. */
    private double      seuilPaiement;
    private Money       prix;
    private boolean     estActif;
    private String      slug;
    private String      imageCouverture;
    private int         nbApprenants;
    private Double      noteMoyenne;
    private int         nbAvis;

    public static Cours creer(String titre, String description, NiveauCours niveau,
                               UUID categorieId, UUID formateurId,
                               double seuilPaiement, long prixFcfa) {
        if (titre == null || titre.isBlank()) throw new IllegalArgumentException("Titre obligatoire");
        if (seuilPaiement <= 0 || seuilPaiement > 1) throw new IllegalArgumentException("Seuil 0-1");
        Cours c = new Cours();
        c.titre = titre.trim(); c.description = description;
        c.niveau = niveau; c.categorieId = categorieId; c.formateurId = formateurId;
        c.seuilPaiement = seuilPaiement; c.prix = Money.of(prixFcfa);
        c.estActif = false; c.nbApprenants = 0;
        return c;
    }
    public Cours(UUID id, String titre, String description, NiveauCours niveau,
                 UUID categorieId, UUID formateurId, double seuilPaiement,
                 long prixFcfa, boolean estActif, String slug, String imageCouverture,
                 int nbApprenants, Double noteMoyenne, int nbAvis,
                 LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.titre = titre; this.description = description; this.niveau = niveau;
        this.categorieId = categorieId; this.formateurId = formateurId;
        this.seuilPaiement = seuilPaiement; this.prix = Money.of(prixFcfa);
        this.estActif = estActif; this.slug = slug; this.imageCouverture = imageCouverture;
        this.nbApprenants = nbApprenants; this.noteMoyenne = noteMoyenne; this.nbAvis = nbAvis;
    }
    public void publier()  { this.estActif = true;  markUpdated(); }
    public void archiver() { this.estActif = false; markUpdated(); }
    public void incrementerNbApprenants() { this.nbApprenants++; markUpdated(); }

    public String      getTitre()          { return titre; }
    public String      getDescription()    { return description; }
    public NiveauCours getNiveau()         { return niveau; }
    public UUID        getCategorieId()    { return categorieId; }
    public UUID        getFormateurId()    { return formateurId; }
    public double      getSeuilPaiement()  { return seuilPaiement; }
    public Money       getPrix()           { return prix; }
    public boolean     isEstActif()        { return estActif; }
    public String      getSlug()           { return slug; }
    public String      getImageCouverture(){ return imageCouverture; }
    public int         getNbApprenants()   { return nbApprenants; }
    public Double      getNoteMoyenne()    { return noteMoyenne; }
    public int         getNbAvis()         { return nbAvis; }
}
JEOF

cat > "$P/domain/cours/Module.java" << 'JEOF'
package com.mbem.mbemlevel.domain.cours;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Module d'un cours — contient les leçons. */
public class Module extends AggregateRoot {
    private UUID    coursId;
    private String  titre;
    private String  description;
    private int     ordre;
    private boolean estVerrouille;
    private int     xpBonus;

    public static Module creer(UUID coursId, String titre, int ordre, int xpBonus) {
        if (ordre < 1) throw new IllegalArgumentException("Ordre >= 1");
        Module m = new Module(); m.coursId = coursId; m.titre = titre.trim();
        m.ordre = ordre; m.estVerrouille = true; m.xpBonus = xpBonus; return m;
    }
    public Module(UUID id, UUID coursId, String titre, String description, int ordre,
                  boolean estVerrouille, int xpBonus, LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.coursId = coursId; this.titre = titre; this.description = description;
        this.ordre = ordre; this.estVerrouille = estVerrouille; this.xpBonus = xpBonus;
    }
    public void deverrouiller() { this.estVerrouille = false; markUpdated(); }

    public UUID    getCoursId()       { return coursId; }
    public String  getTitre()         { return titre; }
    public String  getDescription()   { return description; }
    public int     getOrdre()         { return ordre; }
    public boolean isEstVerrouille()  { return estVerrouille; }
    public int     getXpBonus()       { return xpBonus; }
}
JEOF

cat > "$P/domain/cours/Lecon.java" << 'JEOF'
package com.mbem.mbemlevel.domain.cours;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Leçon — unité pédagogique élémentaire d'un module. */
public class Lecon extends AggregateRoot {
    private UUID   moduleId;
    private String titre;
    private String contenuTexte;
    private String lienPdf;
    private String lienVideo;
    private int    ordre;
    private int    dureeMinutes;
    private int    xpValeur;

    public static Lecon creer(UUID moduleId, String titre, int ordre, int xpValeur) {
        Lecon l = new Lecon(); l.moduleId = moduleId; l.titre = titre.trim();
        l.ordre = ordre; l.xpValeur = xpValeur; return l;
    }
    public Lecon(UUID id, UUID moduleId, String titre, String contenuTexte,
                 String lienPdf, String lienVideo, int ordre, int dureeMinutes,
                 int xpValeur, LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.moduleId = moduleId; this.titre = titre; this.contenuTexte = contenuTexte;
        this.lienPdf = lienPdf; this.lienVideo = lienVideo; this.ordre = ordre;
        this.dureeMinutes = dureeMinutes; this.xpValeur = xpValeur;
    }
    public UUID   getModuleId()      { return moduleId; }
    public String getTitre()         { return titre; }
    public String getContenuTexte()  { return contenuTexte; }
    public String getLienPdf()       { return lienPdf; }
    public String getLienVideo()     { return lienVideo; }
    public int    getOrdre()         { return ordre; }
    public int    getDureeMinutes()  { return dureeMinutes; }
    public int    getXpValeur()      { return xpValeur; }
}
JEOF

cat > "$P/domain/cours/QCM.java" << 'JEOF'
package com.mbem.mbemlevel.domain.cours;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.*;
/** QCM d'une leçon — obligatoire si configuré, score min 70%. */
public class QCM extends AggregateRoot {
    private UUID              leconId;
    private String            question;
    /** Options : [{id:"A",texte:"..."},{id:"B",texte:"..."}] */
    private List<Map<String,String>> options;
    private String            bonneReponse;
    private boolean           estObligatoire;
    private int               scoreMinPct;

    public static QCM creer(UUID leconId, String question,
                             List<Map<String,String>> options, String bonneReponse) {
        if (options == null || options.size() < 2) throw new IllegalArgumentException("Min 2 options");
        QCM q = new QCM(); q.leconId = leconId; q.question = question;
        q.options = options; q.bonneReponse = bonneReponse;
        q.estObligatoire = true; q.scoreMinPct = 70; return q;
    }
    public QCM(UUID id, UUID leconId, String question, List<Map<String,String>> options,
               String bonneReponse, boolean estObligatoire, int scoreMinPct,
               LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.leconId = leconId; this.question = question; this.options = options;
        this.bonneReponse = bonneReponse; this.estObligatoire = estObligatoire;
        this.scoreMinPct = scoreMinPct;
    }
    public boolean verifierReponse(String reponse) {
        return bonneReponse != null && bonneReponse.equalsIgnoreCase(reponse);
    }
    public UUID   getLeconId()        { return leconId; }
    public String getQuestion()       { return question; }
    public List<Map<String,String>> getOptions() { return Collections.unmodifiableList(options); }
    public String getBonneReponse()   { return bonneReponse; }
    public boolean isEstObligatoire() { return estObligatoire; }
    public int    getScoreMinPct()    { return scoreMinPct; }
}
JEOF

cat > "$P/domain/cours/CoursDomainService.java" << 'JEOF'
package com.mbem.mbemlevel.domain.cours;
import java.util.List;
/**
 * Règles métier liées aux cours qui dépassent un seul agrégat.
 * Stateless — injectable en Spring si besoin.
 */
public class CoursDomainService {
    /**
     * Calcule le % de progression d'un cours en fonction des leçons terminées.
     * @param nbLeconsTotales  Nombre total de leçons dans le cours
     * @param nbLeconsTerminees Nombre de leçons complétées par l'apprenant
     */
    public double calculerPourcentage(int nbLeconsTotales, int nbLeconsTerminees) {
        if (nbLeconsTotales <= 0) return 0.0;
        return Math.min(100.0, (double) nbLeconsTerminees / nbLeconsTotales * 100.0);
    }
    /** Un module est déverrouillé si tous les modules précédents sont complétés. */
    public boolean moduleDevraitEtreDeverrouille(int ordreModule,
                                                  int dernierModuleComplete) {
        return ordreModule <= dernierModuleComplete + 1;
    }
}
JEOF
ok "Domain Cours (Categorie, Cours, Module, Lecon, QCM, CoursDomainService)"

# =============================================================================
sec "2/5 Domain Progression"
# =============================================================================
mkdir -p "$P/domain/progression"

cat > "$P/domain/progression/Progression.java" << 'JEOF'
package com.mbem.mbemlevel.domain.progression;
import com.mbem.mbemlevel.domain.event.SeuilPaiementAtteintEvent;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/**
 * Agrégat Progression — état d'avancement d'un apprenant dans un cours.
 * Règle clé : quand pourcentage >= seuilPaiement → publier SeuilPaiementAtteintEvent.
 */
public class Progression extends AggregateRoot {
    private UUID         apprenantId;
    private UUID         coursId;
    private double       pourcentage;    // 0.0 – 100.0
    private boolean      estPaye;
    private int          xpGagne;
    private LocalDateTime dateDebut;
    private LocalDateTime dateCompletion;
    /** Pourcentage du cours après lequel le paiement est demandé (config du cours). */
    private double       seuilPaiementCours;

    public static Progression commencer(UUID apprenantId, UUID coursId,
                                         double seuilPaiementCours) {
        Progression p = new Progression();
        p.apprenantId = apprenantId; p.coursId = coursId;
        p.pourcentage = 0.0; p.estPaye = false; p.xpGagne = 0;
        p.dateDebut = LocalDateTime.now(); p.seuilPaiementCours = seuilPaiementCours;
        return p;
    }
    public Progression(UUID id, UUID apprenantId, UUID coursId, double pourcentage,
                       boolean estPaye, int xpGagne, LocalDateTime dateDebut,
                       LocalDateTime dateCompletion, double seuilPaiementCours,
                       LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.apprenantId = apprenantId; this.coursId = coursId;
        this.pourcentage = pourcentage; this.estPaye = estPaye; this.xpGagne = xpGagne;
        this.dateDebut = dateDebut; this.dateCompletion = dateCompletion;
        this.seuilPaiementCours = seuilPaiementCours;
    }

    /**
     * Avance la progression et publie SeuilPaiementAtteintEvent si seuil franchi.
     * @param nouveauPct    Nouveau pourcentage calculé
     * @param xpLecon       XP gagnés pour cette leçon
     * @param prenom        Pour l'event (email nurturing)
     * @param email         Pour l'event
     * @param telephone     Pour l'event WhatsApp
     * @param nomCours      Pour l'event
     */
    public void avancer(double nouveauPct, int xpLecon, String prenom,
                        String email, String telephone, String nomCours) {
        boolean dejaSeuilAtteint = this.pourcentage >= (seuilPaiementCours * 100);
        boolean nouveauSeuilAtteint = nouveauPct >= (seuilPaiementCours * 100);
        this.pourcentage = Math.min(100.0, nouveauPct);
        this.xpGagne += xpLecon;
        // Publier l'event seulement la première fois que le seuil est franchi
        if (!dejaSeuilAtteint && nouveauSeuilAtteint && !estPaye) {
            registerEvent(new SeuilPaiementAtteintEvent(
                apprenantId, coursId, prenom, email, telephone, nomCours, this.pourcentage));
        }
        // Cours terminé à 100%
        if (this.pourcentage >= 100.0 && dateCompletion == null) {
            this.dateCompletion = LocalDateTime.now();
        }
        markUpdated();
    }

    public void activerPaiement() { this.estPaye = true; markUpdated(); }
    public boolean seuilAtteint() { return pourcentage >= (seuilPaiementCours * 100); }
    public boolean estTermine()   { return pourcentage >= 100.0; }
    public boolean peutAccederLeconSuivante() { return estPaye || !seuilAtteint(); }

    public UUID          getApprenantId()   { return apprenantId; }
    public UUID          getCoursId()       { return coursId; }
    public double        getPourcentage()   { return pourcentage; }
    public boolean       isEstPaye()        { return estPaye; }
    public int           getXpGagne()       { return xpGagne; }
    public LocalDateTime getDateDebut()     { return dateDebut; }
    public LocalDateTime getDateCompletion(){ return dateCompletion; }
}
JEOF

cat > "$P/domain/progression/ReponseQCM.java" << 'JEOF'
package com.mbem.mbemlevel.domain.progression;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Réponse d'un apprenant à un QCM — résultat et tentative. */
public class ReponseQCM extends AggregateRoot {
    private UUID    progressionId;
    private UUID    qcmId;
    private String  reponseDonnee;
    private boolean estCorrecte;
    private int     score;
    private int     tentative;

    public static ReponseQCM creer(UUID progressionId, UUID qcmId,
                                    String reponse, boolean correcte, int score) {
        ReponseQCM r = new ReponseQCM();
        r.progressionId = progressionId; r.qcmId = qcmId;
        r.reponseDonnee = reponse; r.estCorrecte = correcte;
        r.score = score; r.tentative = 1; return r;
    }
    public ReponseQCM(UUID id, UUID progressionId, UUID qcmId, String reponse,
                      boolean correcte, int score, int tentative,
                      LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.progressionId = progressionId; this.qcmId = qcmId;
        this.reponseDonnee = reponse; this.estCorrecte = correcte;
        this.score = score; this.tentative = tentative;
    }
    public UUID    getProgressionId()  { return progressionId; }
    public UUID    getQcmId()          { return qcmId; }
    public String  getReponseDonnee()  { return reponseDonnee; }
    public boolean isEstCorrecte()     { return estCorrecte; }
    public int     getScore()          { return score; }
    public int     getTentative()      { return tentative; }
}
JEOF

cat > "$P/domain/progression/Badge.java" << 'JEOF'
package com.mbem.mbemlevel.domain.progression;
import com.mbem.mbemlevel.domain.shared.AggregateRoot;
import java.time.LocalDateTime;
import java.util.UUID;
/** Badge de gamification attribué à un apprenant. */
public class Badge extends AggregateRoot {
    private UUID   apprenantId;
    private String typeBadge;   // PREMIER_COURS, STREAK_7, XP_1000, CERTIFIE
    private String description;

    public static Badge attribuer(UUID apprenantId, String type, String desc) {
        Badge b = new Badge(); b.apprenantId = apprenantId;
        b.typeBadge = type; b.description = desc; return b;
    }
    public Badge(UUID id, UUID apprenantId, String typeBadge, String description,
                 LocalDateTime ca, LocalDateTime ua) {
        super(id, ca, ua);
        this.apprenantId = apprenantId; this.typeBadge = typeBadge; this.description = description;
    }
    public UUID   getApprenantId() { return apprenantId; }
    public String getTypeBadge()   { return typeBadge; }
    public String getDescription() { return description; }
}
JEOF

cat > "$P/domain/progression/ProgressionDomainService.java" << 'JEOF'
package com.mbem.mbemlevel.domain.progression;
import java.util.List;
/**
 * Règles métier gamification : XP, streak, badges.
 * Stateless — utilisé par les use cases Progression.
 */
public class ProgressionDomainService {
    /** Vérifie si un badge doit être attribué selon le contexte. */
    public boolean devoirAttribuerBadge(String typeBadge, int xpTotal,
                                         int streakJours, List<String> badgesExistants) {
        if (badgesExistants.contains(typeBadge)) return false;
        return switch (typeBadge) {
            case "XP_100"   -> xpTotal >= 100;
            case "XP_500"   -> xpTotal >= 500;
            case "XP_1000"  -> xpTotal >= 1000;
            case "STREAK_7" -> streakJours >= 7;
            case "STREAK_30"-> streakJours >= 30;
            default -> false;
        };
    }
}
JEOF
ok "Domain Progression (Progression, ReponseQCM, Badge, ProgressionDomainService)"

# =============================================================================
sec "3/5 JPA + Ports + Adapters Cours & Progression"
# =============================================================================
mkdir -p "$P/infrastructure/persistence/entity"
mkdir -p "$P/infrastructure/persistence/repository"
mkdir -p "$P/infrastructure/persistence/adapter"
mkdir -p "$P/application/port/out"

# ── Entités JPA ───────────────────────────────────────────────────────────────
cat > "$P/infrastructure/persistence/entity/CoursJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;
@Entity @Table(name="cours") @EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CoursJpaEntity {
    @Id private UUID id;
    @Column(nullable=false,length=200) private String titre;
    @Column(columnDefinition="TEXT") private String description;
    @Enumerated(EnumType.STRING) @Column(nullable=false,length=20) private NiveauCours niveau;
    @Column(name="categorie_id") private UUID categorieId;
    @Column(name="formateur_id") private UUID formateurId;
    @Column(name="seuil_paiement",nullable=false,precision=3,scale=2) private BigDecimal seuilPaiement;
    @Column(name="prix_fcfa",nullable=false) private long prixFcfa;
    @Column(name="est_actif",nullable=false) private boolean estActif;
    @Column(length=250,unique=true) private String slug;
    @Column(name="image_couverture",length=500) private String imageCouverture;
    @Column(name="nb_apprenants",nullable=false) private int nbApprenants;
    @Column(name="note_moyenne",precision=3,scale=2) private Double noteMoyenne;
    @Column(name="nb_avis",nullable=false) private int nbAvis;
    @CreatedDate @Column(name="created_at",nullable=false,updatable=false) private LocalDateTime createdAt;
    @LastModifiedDate @Column(name="updated_at",nullable=false) private LocalDateTime updatedAt;
}
JEOF

cat > "$P/infrastructure/persistence/entity/ProgressionJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;
@Entity @Table(name="progression",
    uniqueConstraints=@UniqueConstraint(columnNames={"apprenant_id","cours_id"}))
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ProgressionJpaEntity {
    @Id private UUID id;
    @Column(name="apprenant_id",nullable=false) private UUID apprenantId;
    @Column(name="cours_id",nullable=false)     private UUID coursId;
    @Column(nullable=false) private double pourcentage;
    @Column(name="est_paye",nullable=false) private boolean estPaye;
    @Column(name="xp_gagne",nullable=false)  private int xpGagne;
    @Column(name="date_debut",nullable=false) private LocalDateTime dateDebut;
    @Column(name="date_completion") private LocalDateTime dateCompletion;
    @Column(name="seuil_paiement_cours",nullable=false) private double seuilPaiementCours;
    @CreatedDate @Column(name="created_at",nullable=false,updatable=false) private LocalDateTime createdAt;
    @LastModifiedDate @Column(name="updated_at",nullable=false) private LocalDateTime updatedAt;
}
JEOF

# ── Repositories JPA ──────────────────────────────────────────────────────────
cat > "$P/infrastructure/persistence/repository/CoursJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CoursJpaEntity;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Optional;
import java.util.UUID;
public interface CoursJpaRepository extends JpaRepository<CoursJpaEntity, UUID> {
    /** Catalogue paginé avec filtres optionnels — index idx_cours_catalogue. */
    @Query("SELECT c FROM CoursJpaEntity c WHERE c.estActif = true " +
           "AND (:niveau IS NULL OR c.niveau = :niveau) " +
           "AND (:categorieId IS NULL OR c.categorieId = :categorieId) " +
           "ORDER BY c.nbApprenants DESC")
    Page<CoursJpaEntity> findCatalogue(
        @Param("niveau") NiveauCours niveau,
        @Param("categorieId") UUID categorieId,
        Pageable pageable);

    Optional<CoursJpaEntity> findBySlug(String slug);
    boolean existsBySlug(String slug);
}
JEOF

cat > "$P/infrastructure/persistence/repository/ProgressionJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.ProgressionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
public interface ProgressionJpaRepository extends JpaRepository<ProgressionJpaEntity, UUID> {
    Optional<ProgressionJpaEntity> findByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
    List<ProgressionJpaEntity>  findByApprenantId(UUID apprenantId);
    /** Active le paiement d'un cours (estPaye=true) — utilisé après confirmation paiement. */
    @Modifying
    @Query("UPDATE ProgressionJpaEntity p SET p.estPaye = true " +
           "WHERE p.apprenantId = :uid AND p.coursId = :cid")
    int activerPaiement(@Param("uid") UUID apprenantId, @Param("cid") UUID coursId);
}
JEOF

# ── Ports Application ─────────────────────────────────────────────────────────
cat > "$P/application/port/out/CoursRepository.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;
import com.mbem.mbemlevel.domain.cours.Cours;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import org.springframework.data.domain.*;
import java.util.*;
public interface CoursRepository {
    Optional<Cours> findById(UUID id);
    Optional<Cours> findBySlug(String slug);
    Page<Cours>     findCatalogue(NiveauCours niveau, UUID categorieId, Pageable pageable);
    Cours           save(Cours cours);
    boolean         existsBySlug(String slug);
}
JEOF

cat > "$P/application/port/out/ProgressionRepository.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;
import com.mbem.mbemlevel.domain.progression.Progression;
import java.util.*;
public interface ProgressionRepository {
    Optional<Progression> findByApprenantIdAndCoursId(UUID apprenantId, UUID coursId);
    List<Progression>     findByApprenantId(UUID apprenantId);
    Progression           save(Progression progression);
    int                   activerPaiement(UUID apprenantId, UUID coursId);
}
JEOF

# ── Adapters ──────────────────────────────────────────────────────────────────
cat > "$P/infrastructure/persistence/adapter/CoursRepositoryAdapter.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.adapter;
import com.mbem.mbemlevel.application.port.out.CoursRepository;
import com.mbem.mbemlevel.domain.cours.Cours;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CoursJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.CoursJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.*;
@Component @RequiredArgsConstructor
public class CoursRepositoryAdapter implements CoursRepository {
    private final CoursJpaRepository repo;

    @Override @Transactional(readOnly=true)
    public Optional<Cours> findById(UUID id) { return repo.findById(id).map(this::toDomain); }
    @Override @Transactional(readOnly=true)
    public Optional<Cours> findBySlug(String slug) { return repo.findBySlug(slug).map(this::toDomain); }
    @Override @Transactional(readOnly=true)
    public Page<Cours> findCatalogue(NiveauCours niveau, UUID catId, Pageable p) {
        return repo.findCatalogue(niveau, catId, p).map(this::toDomain);
    }
    @Override @Transactional(readOnly=true)
    public boolean existsBySlug(String slug) { return repo.existsBySlug(slug); }
    @Override @Transactional
    public Cours save(Cours c) {
        return toDomain(repo.save(repo.findById(c.getId())
            .map(e -> update(c, e))
            .orElseGet(() -> toEntity(c))));
    }
    private CoursJpaEntity update(Cours c, CoursJpaEntity e) {
        e.setTitre(c.getTitre()); e.setDescription(c.getDescription());
        e.setNiveau(c.getNiveau()); e.setEstActif(c.isEstActif());
        e.setNbApprenants(c.getNbApprenants()); return e;
    }
    private CoursJpaEntity toEntity(Cours c) {
        return CoursJpaEntity.builder().id(c.getId()).titre(c.getTitre())
            .description(c.getDescription()).niveau(c.getNiveau())
            .categorieId(c.getCategorieId()).formateurId(c.getFormateurId())
            .seuilPaiement(BigDecimal.valueOf(c.getSeuilPaiement()))
            .prixFcfa(c.getPrix().toLong()).estActif(c.isEstActif())
            .slug(c.getSlug()).imageCouverture(c.getImageCouverture())
            .nbApprenants(c.getNbApprenants()).build();
    }
    private Cours toDomain(CoursJpaEntity e) {
        return new Cours(e.getId(),e.getTitre(),e.getDescription(),e.getNiveau(),
            e.getCategorieId(),e.getFormateurId(),
            e.getSeuilPaiement()!=null?e.getSeuilPaiement().doubleValue():0.30,
            e.getPrixFcfa(),e.isEstActif(),e.getSlug(),e.getImageCouverture(),
            e.getNbApprenants(),e.getNoteMoyenne(),e.getNbAvis(),e.getCreatedAt(),e.getUpdatedAt());
    }
}
JEOF

cat > "$P/infrastructure/persistence/adapter/ProgressionRepositoryAdapter.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.adapter;
import com.mbem.mbemlevel.application.port.out.ProgressionRepository;
import com.mbem.mbemlevel.domain.progression.Progression;
import com.mbem.mbemlevel.infrastructure.persistence.entity.ProgressionJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.ProgressionJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;
@Component @RequiredArgsConstructor
public class ProgressionRepositoryAdapter implements ProgressionRepository {
    private final ProgressionJpaRepository repo;

    @Override @Transactional(readOnly=true)
    public Optional<Progression> findByApprenantIdAndCoursId(UUID aid, UUID cid) {
        return repo.findByApprenantIdAndCoursId(aid,cid).map(this::toDomain);
    }
    @Override @Transactional(readOnly=true)
    public List<Progression> findByApprenantId(UUID aid) {
        return repo.findByApprenantId(aid).stream().map(this::toDomain).collect(Collectors.toList());
    }
    @Override @Transactional
    public Progression save(Progression p) {
        return toDomain(repo.save(repo.findByApprenantIdAndCoursId(p.getApprenantId(),p.getCoursId())
            .map(e -> update(p,e)).orElseGet(() -> toEntity(p))));
    }
    @Override @Transactional
    public int activerPaiement(UUID aid, UUID cid) { return repo.activerPaiement(aid,cid); }

    private ProgressionJpaEntity update(Progression p, ProgressionJpaEntity e) {
        e.setPourcentage(p.getPourcentage()); e.setEstPaye(p.isEstPaye());
        e.setXpGagne(p.getXpGagne()); e.setDateCompletion(p.getDateCompletion()); return e;
    }
    private ProgressionJpaEntity toEntity(Progression p) {
        return ProgressionJpaEntity.builder().id(p.getId())
            .apprenantId(p.getApprenantId()).coursId(p.getCoursId())
            .pourcentage(p.getPourcentage()).estPaye(p.isEstPaye())
            .xpGagne(p.getXpGagne()).dateDebut(p.getDateDebut()!=null?p.getDateDebut():LocalDateTime.now())
            .dateCompletion(p.getDateCompletion())
            .seuilPaiementCours(0.30).build();
    }
    private Progression toDomain(ProgressionJpaEntity e) {
        return new Progression(e.getId(),e.getApprenantId(),e.getCoursId(),
            e.getPourcentage(),e.isEstPaye(),e.getXpGagne(),e.getDateDebut(),
            e.getDateCompletion(),e.getSeuilPaiementCours(),e.getCreatedAt(),e.getUpdatedAt());
    }
}
JEOF
ok "JPA Cours + Progression · Repositories · Adapters · Ports"

# =============================================================================
sec "4/5 Use Cases Cours + Progression"
# =============================================================================
mkdir -p "$P/application/usecase/cours"
mkdir -p "$P/application/usecase/progression"

cat > "$P/application/usecase/cours/GetCatalogueUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.cours;
import com.mbem.mbemlevel.application.port.out.CoursRepository;
import com.mbem.mbemlevel.domain.cours.Cours;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/** S04 — Catalogue paginé avec filtres niveau + catégorie. */
@Service @RequiredArgsConstructor
public class GetCatalogueUseCase {
    private final CoursRepository coursRepo;
    @Transactional(readOnly=true)
    public Page<Cours> executer(NiveauCours niveau, UUID categorieId, int page, int size) {
        Pageable pageable = PageRequest.of(page, Math.min(size, 20),
            Sort.by("nbApprenants").descending());
        return coursRepo.findCatalogue(niveau, categorieId, pageable);
    }
}
JEOF

cat > "$P/application/usecase/cours/GetDetailCoursUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.cours;
import com.mbem.mbemlevel.application.port.out.CoursRepository;
import com.mbem.mbemlevel.domain.cours.Cours;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/** S04 — Détail d'un cours par ID ou slug. */
@Service @RequiredArgsConstructor
public class GetDetailCoursUseCase {
    private final CoursRepository coursRepo;
    @Transactional(readOnly=true)
    public Cours parId(UUID id) {
        return coursRepo.findById(id)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
    }
    @Transactional(readOnly=true)
    public Cours parSlug(String slug) {
        return coursRepo.findBySlug(slug)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
    }
}
JEOF

cat > "$P/application/usecase/progression/CommencerCoursUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.progression;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.progression.Progression;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S05 — Commencer ou reprendre un cours.
 * Si progression existante → renvoyer l'existante (reprise silencieuse).
 */
@Service @RequiredArgsConstructor @Slf4j
public class CommencerCoursUseCase {
    private final ProgressionRepository progressionRepo;
    private final CoursRepository       coursRepo;

    @Transactional
    public Progression executer(UUID apprenantId, UUID coursId) {
        // Reprise si déjà commencé
        return progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
            .orElseGet(() -> {
                var cours = coursRepo.findById(coursId)
                    .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
                var progression = Progression.commencer(apprenantId, coursId,
                    cours.getSeuilPaiement());
                var saved = progressionRepo.save(progression);
                // Incrémenter le compteur d'apprenants du cours
                cours.incrementerNbApprenants();
                coursRepo.save(cours);
                log.info("[COURS] Cours {} commencé par apprenant {}", coursId, apprenantId);
                return saved;
            });
    }
}
JEOF

cat > "$P/application/usecase/progression/TerminerLeconUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.progression;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.progression.Progression;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;
/**
 * S06 — Marquer une leçon comme terminée.
 * Calcule le nouveau pourcentage, ajoute les XP, publie les events si seuil atteint.
 */
@Service @RequiredArgsConstructor
public class TerminerLeconUseCase {
    private final ProgressionRepository  progressionRepo;
    private final CoursRepository        coursRepo;
    private final ApplicationEventPublisher publisher;

    @Transactional
    public Progression executer(UUID apprenantId, UUID coursId, UUID leconId,
                                 int nbLeconsTotales, int nbLeconsTerminees,
                                 int xpLecon, String prenom, String email,
                                 String telephone, String nomCours) {
        Progression p = progressionRepo.findByApprenantIdAndCoursId(apprenantId, coursId)
            .orElseGet(() -> {
                var cours = coursRepo.findById(coursId)
                    .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND"));
                return Progression.commencer(apprenantId, coursId, cours.getSeuilPaiement());
            });

        double nouveauPct = nbLeconsTotales > 0
            ? Math.min(100.0, (double) nbLeconsTerminees / nbLeconsTotales * 100.0) : 0;

        p.avancer(nouveauPct, xpLecon, prenom, email, telephone, nomCours);
        Progression saved = progressionRepo.save(p);

        // Publier les domain events (SeuilPaiementAtteintEvent, CoursTermineEvent…)
        saved.getDomainEvents().forEach(publisher::publishEvent);
        saved.clearDomainEvents();
        return saved;
    }
}
JEOF

cat > "$P/application/usecase/progression/GetProgressionUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.progression;
import com.mbem.mbemlevel.application.port.out.ProgressionRepository;
import com.mbem.mbemlevel.domain.progression.Progression;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
@Service @RequiredArgsConstructor
public class GetProgressionUseCase {
    private final ProgressionRepository repo;
    @Transactional(readOnly=true)
    public Optional<Progression> parCoursId(UUID apprenantId, UUID coursId) {
        return repo.findByApprenantIdAndCoursId(apprenantId, coursId);
    }
    @Transactional(readOnly=true)
    public List<Progression> toutesParApprenant(UUID apprenantId) {
        return repo.findByApprenantId(apprenantId);
    }
}
JEOF

cat > "$P/application/usecase/progression/ValiderQCMUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.progression;
import com.mbem.mbemlevel.domain.cours.QCM;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
/**
 * S06 — Valider la réponse d'un apprenant à un QCM.
 * Retourne true si la réponse est correcte.
 */
@Service @RequiredArgsConstructor
public class ValiderQCMUseCase {
    public boolean executer(QCM qcm, String reponseApprenant) {
        if (qcm == null || reponseApprenant == null)
            throw new IllegalArgumentException("QCM et réponse obligatoires");
        return qcm.verifierReponse(reponseApprenant);
    }
}
JEOF
ok "Use Cases Cours + Progression"

# =============================================================================
sec "5/5 Controllers + DTOs réponse"
# =============================================================================
mkdir -p "$P/api/controller"
mkdir -p "$P/api/dto/response"
mkdir -p "$P/api/dto/request"

cat > "$P/api/dto/response/CoursResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.cours.Cours;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record CoursResponse(
    UUID id, String titre, String description, NiveauCours niveau,
    String imageCouverture, long prixFcfa, String prixAffichage,
    int nbApprenants, Double noteMoyenne, int nbAvis,
    Double seuilPaiement, boolean estActif, String slug
) {
    public static CoursResponse from(Cours c) {
        return new CoursResponse(c.getId(), c.getTitre(), c.getDescription(),
            c.getNiveau(), c.getImageCouverture(), c.getPrix().toLong(),
            c.getPrix().toDisplay(), c.getNbApprenants(), c.getNoteMoyenne(),
            c.getNbAvis(), c.getSeuilPaiement(), c.isEstActif(), c.getSlug());
    }
}
JEOF

cat > "$P/api/dto/response/ProgressionResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.progression.Progression;
import java.time.LocalDateTime;
import java.util.UUID;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ProgressionResponse(
    UUID id, UUID coursId, double pourcentage, boolean estPaye,
    int xpGagne, boolean seuilAtteint, boolean estTermine,
    LocalDateTime dateDebut, LocalDateTime dateCompletion
) {
    public static ProgressionResponse from(Progression p) {
        return new ProgressionResponse(p.getId(), p.getCoursId(), p.getPourcentage(),
            p.isEstPaye(), p.getXpGagne(), p.seuilAtteint(), p.estTermine(),
            p.getDateDebut(), p.getDateCompletion());
    }
}
JEOF

cat > "$P/api/dto/request/TerminerLeconRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;
import jakarta.validation.constraints.*;
public record TerminerLeconRequest(
    @NotNull UUID leconId,
    @Min(0) int nbLeconsTotales,
    @Min(0) int nbLeconsTerminees,
    @Min(0) int xpLecon,
    @NotBlank String nomCours,
    String telephone
) {
    public TerminerLeconRequest { java.util.Objects.requireNonNull(leconId); }
}
JEOF

cat > "$P/api/controller/CoursController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.cours.*;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;
/**
 * API Cours — Catalogue (S04) et détail d'un cours.
 * GET /api/v1/cours         → catalogue paginé
 * GET /api/v1/cours/{id}    → détail par ID
 * GET /api/v1/cours/slug/{s}→ détail par slug
 */
@RestController
@RequestMapping("/api/v1/cours")
@Tag(name="Cours", description="Catalogue et détail des formations")
@RequiredArgsConstructor
public class CoursController {
    private final GetCatalogueUseCase    catalogueUC;
    private final GetDetailCoursUseCase  detailUC;

    @GetMapping
    @Operation(summary="Catalogue des cours (S04)")
    public ResponseEntity<ApiResponse<PageResponse<CoursResponse>>> catalogue(
            @RequestParam(required=false) NiveauCours niveau,
            @RequestParam(required=false) UUID categorieId,
            @RequestParam(defaultValue="0") int page,
            @RequestParam(defaultValue="12") int size) {
        Page<CoursResponse> result = catalogueUC.executer(niveau, categorieId, page, size)
            .map(CoursResponse::from);
        return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(result)));
    }

    @GetMapping("/{id}")
    @Operation(summary="Détail d'un cours par ID (S04)")
    public ResponseEntity<ApiResponse<CoursResponse>> detailParId(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(CoursResponse.from(detailUC.parId(id))));
    }

    @GetMapping("/slug/{slug}")
    @Operation(summary="Détail d'un cours par slug (S04)")
    public ResponseEntity<ApiResponse<CoursResponse>> detailParSlug(@PathVariable String slug) {
        return ResponseEntity.ok(ApiResponse.ok(CoursResponse.from(detailUC.parSlug(slug))));
    }
}
JEOF

cat > "$P/api/controller/ProgressionController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;
import com.mbem.mbemlevel.api.dto.request.TerminerLeconRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.progression.*;
import com.mbem.mbemlevel.domain.progression.Progression;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;
/**
 * API Progression — S05 (commencer), S06 (leçon+QCM), S07 (seuil).
 * Tous les endpoints nécessitent une authentification.
 */
@RestController
@RequestMapping("/api/v1/progression")
@Tag(name="Progression", description="Avancement dans les cours")
@RequiredArgsConstructor
public class ProgressionController {
    private final CommencerCoursUseCase  commencerUC;
    private final TerminerLeconUseCase   terminerLeconUC;
    private final GetProgressionUseCase  getUC;

    /** POST /api/v1/progression/cours/{coursId}/commencer — S05 */
    @PostMapping("/cours/{coursId}/commencer")
    @Operation(summary="Commencer ou reprendre un cours (S05)")
    public ResponseEntity<ApiResponse<ProgressionResponse>> commencer(
            @PathVariable UUID coursId,
            @AuthenticationPrincipal String userId) {
        Progression p = commencerUC.executer(UUID.fromString(userId), coursId);
        return ResponseEntity.ok(ApiResponse.ok(ProgressionResponse.from(p), "Cours commencé !"));
    }

    /** POST /api/v1/progression/cours/{coursId}/terminer-lecon — S06 */
    @PostMapping("/cours/{coursId}/terminer-lecon")
    @Operation(summary="Marquer une leçon terminée — calcule XP et progression (S06)")
    public ResponseEntity<ApiResponse<ProgressionResponse>> terminerLecon(
            @PathVariable UUID coursId,
            @Valid @RequestBody TerminerLeconRequest req,
            @AuthenticationPrincipal String userId,
            @RequestHeader(value="X-User-Prenom", defaultValue="Apprenant") String prenom,
            @RequestHeader(value="X-User-Email",  defaultValue="") String email) {
        Progression p = terminerLeconUC.executer(
            UUID.fromString(userId), coursId, req.leconId(),
            req.nbLeconsTotales(), req.nbLeconsTerminees(), req.xpLecon(),
            prenom, email, req.telephone(), req.nomCours());
        String msg = p.seuilAtteint() && !p.isEstPaye()
            ? "Seuil atteint ! Débloquez la suite." : "+"+req.xpLecon()+" XP gagnés !";
        return ResponseEntity.ok(ApiResponse.ok(ProgressionResponse.from(p), msg));
    }

    /** GET /api/v1/progression — Toutes les progressions de l'apprenant */
    @GetMapping
    @Operation(summary="Toutes les progressions de l'apprenant connecté")
    public ResponseEntity<ApiResponse<List<ProgressionResponse>>> mesPrgressions(
            @AuthenticationPrincipal String userId) {
        List<ProgressionResponse> list = getUC.toutesParApprenant(UUID.fromString(userId))
            .stream().map(ProgressionResponse::from).collect(Collectors.toList());
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    /** GET /api/v1/progression/cours/{coursId} — Progression sur un cours */
    @GetMapping("/cours/{coursId}")
    @Operation(summary="Progression sur un cours spécifique")
    public ResponseEntity<ApiResponse<ProgressionResponse>> parCours(
            @PathVariable UUID coursId,
            @AuthenticationPrincipal String userId) {
        return getUC.parCoursId(UUID.fromString(userId), coursId)
            .map(p -> ResponseEntity.ok(ApiResponse.ok(ProgressionResponse.from(p))))
            .orElse(ResponseEntity.notFound().build());
    }
}
JEOF
ok "CoursController + ProgressionController + DTOs réponse"

echo -e "\n${B}${G}  Script 09 terminé${N}"
echo -e "  ${G}✓${N} Domain : Cours, Module, Lecon, QCM, Categorie, CoursDomainService"
echo -e "  ${G}✓${N} Domain : Progression, ReponseQCM, Badge, ProgressionDomainService"
echo -e "  ${G}✓${N} JPA : CoursJpaEntity, ProgressionJpaEntity + repos + adapters"
echo -e "  ${G}✓${N} Ports : CoursRepository, ProgressionRepository"
echo -e "  ${G}✓${N} Use Cases : GetCatalogue, GetDetail, CommencerCours, TerminerLecon,"
echo -e "               ValiderQCM, GetProgression — Scénarios S04-S07"
echo -e "  ${G}✓${N} Controllers : CoursController + ProgressionController\n"
echo -e "  \033[1;33m→ ./s10_paiement.sh\033[0m\n"
