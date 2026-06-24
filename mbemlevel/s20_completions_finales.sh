#!/usr/bin/env bash
# =============================================================================
# MbemNova — s20_completions_finales.sh
# Dernières complétions :
#  1. QCMJpaEntity + QCMJpaRepository (absents totalement)
#  2. LeconJpaEntity + ModuleJpaEntity avec champs LMS complets
#  3. SessionJpaEntity champs manquants (statut, lieuOuLien, placesDisponibles)
#  4. SessionJpaRepository + méthode conflit horaire formateur
#  5. MessageCommunauteJpaEntity — nbSignalements + estMasque
#  6. CoursJpaRepository — findByStatutIn
#  7. UtilisateurJpaEntity — codeParrainage
#  8. TrancheRepository (port out) + updateDateEcheance
#  9. ProgressionDomainService — vrai calcul streak + XP
# 10. Endpoints manquants dans controllers existants (moratoire, QCM,
#     créneaux, avis, parrainage, devoir listing, talent PUT, communauté signalement,
#     RGPD delete/export)
# 11. RappelInscriptionScheduler (S2) + SeuilNonConvertiScheduler (S7)
# =============================================================================
set -euo pipefail
ROOT="${1:-.}"
P="$ROOT/src/main/java/com/mbem/mbemlevel"
C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_NC='\033[0m'
ok()  { echo -e "  ${C_GREEN}✓${C_NC}  $1"; }
sec() { echo -e "\n${C_BLUE}▶ $1${C_NC}"; }

mkdir -p "$P/infrastructure/persistence/entity"
mkdir -p "$P/infrastructure/persistence/repository"
mkdir -p "$P/infrastructure/persistence/adapter"
mkdir -p "$P/application/port/out"
mkdir -p "$P/application/usecase/progression"
mkdir -p "$P/domain/progression"
mkdir -p "$P/infrastructure/scheduler"
mkdir -p "$P/api/controller"

echo -e "\n${C_BLUE}══════════════════════════════════════════════════════════${C_NC}"
echo -e "${C_BLUE}  MbemNova · s20 · Complétions finales                     ${C_NC}"
echo -e "${C_BLUE}══════════════════════════════════════════════════════════${C_NC}\n"

# =============================================================================
# 1. QCMJpaEntity + QCMJpaRepository — entièrement absents
# =============================================================================
sec "1/11 QCMJpaEntity + QCMJpaRepository"

cat > "$P/infrastructure/persistence/entity/QCMJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entité JPA du QCM d'une leçon.
 * Options stockées en JSONB : [{"id":"A","texte":"..."},{"id":"B","texte":"..."}]
 * La bonne réponse n'est JAMAIS envoyée au front sauf après soumission.
 */
@Entity
@Table(name = "qcm")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class QCMJpaEntity {

    @Id
    private UUID id;

    @Column(name = "lecon_id", nullable = false)
    private UUID leconId;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String question;

    /**
     * JSON array des options : [{"id":"A","texte":"..."},{"id":"B","texte":"..."}]
     * Stocké en TEXT — parsé côté applicatif avec ObjectMapper.
     */
    @Column(name = "options_json", nullable = false, columnDefinition = "TEXT")
    private String optionsJson;

    /** Identifiant de la bonne réponse : "A", "B", "C" ou "D" */
    @Column(name = "bonne_reponse", nullable = false, length = 1)
    private String bonneReponse;

    /**
     * Explication affichée après soumission.
     * Ex: "La bonne réponse est B car Spring Boot gère l'IoC automatiquement."
     */
    @Column(columnDefinition = "TEXT")
    private String explication;

    @Column(name = "score_points", nullable = false)
    private int scorePoints;

    @Column(nullable = false)
    private int ordre;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
JEOF
ok "QCMJpaEntity"

cat > "$P/infrastructure/persistence/repository/QCMJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.QCMJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface QCMJpaRepository extends JpaRepository<QCMJpaEntity, UUID> {
    /** QCM d'une leçon (une leçon peut avoir plusieurs questions) */
    List<QCMJpaEntity> findByLeconIdOrderByOrdreAsc(UUID leconId);

    /** Premier QCM d'une leçon (cas simple : une question par leçon) */
    Optional<QCMJpaEntity> findByLeconId(UUID leconId);

    boolean existsByLeconId(UUID leconId);
}
JEOF
ok "QCMJpaRepository"

# =============================================================================
# 2. LeconJpaEntity et ModuleJpaEntity avec champs LMS complets
# =============================================================================
sec "2/11 LeconJpaEntity + ModuleJpaEntity (champs LMS complets)"

cat > "$P/infrastructure/persistence/entity/LeconJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "lecons")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class LeconJpaEntity {

    @Id
    private UUID id;

    @Column(name = "module_id", nullable = false)
    private UUID moduleId;

    @Column(nullable = false, length = 200)
    private String titre;

    @Column(name = "description_courte", length = 500)
    private String descriptionCourte;

    /** Contenu texte simple (legacy — remplacé par blocs_contenu) */
    @Column(name = "contenu_texte", columnDefinition = "TEXT")
    private String contenuTexte;

    /** Lien PDF direct (legacy — remplacé par blocs_contenu type PDF_EMBED) */
    @Column(name = "lien_pdf", length = 500)
    private String lienPdf;

    /** Lien vidéo (legacy — remplacé par blocs_contenu type VIDEO_YOUTUBE) */
    @Column(name = "lien_video", length = 500)
    private String lienVideo;

    @Column(nullable = false)
    private int ordre;

    @Column(name = "duree_minutes")
    private int dureeMinutes;

    @Column(name = "xp_valeur", nullable = false)
    private int xpValeur;

    /**
     * Leçon accessible sans payer — aperçu gratuit avant le seuil.
     */
    @Column(name = "est_preview", nullable = false)
    private boolean estPreview;

    /**
     * Indique si cette leçon a un QCM associé.
     * Dénormalisation pour éviter un JOIN sur qcm à chaque affichage de liste.
     */
    @Column(name = "a_qcm", nullable = false)
    private boolean aQCM;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
JEOF
ok "LeconJpaEntity"

cat > "$P/infrastructure/persistence/entity/ModuleJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "modules")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ModuleJpaEntity {

    @Id
    private UUID id;

    @Column(name = "cours_id", nullable = false)
    private UUID coursId;

    @Column(nullable = false, length = 200)
    private String titre;

    @Column(length = 500)
    private String description;

    @Column(nullable = false)
    private int ordre;

    @Column(name = "est_verrouille", nullable = false)
    private boolean estVerrouille;

    @Column(name = "xp_bonus", nullable = false)
    private int xpBonus;

    /**
     * Module entièrement gratuit — accessible avant le seuil de paiement.
     * Typiquement vrai pour le module d'introduction.
     */
    @Column(name = "est_gratuit", nullable = false)
    private boolean estGratuit;

    /** Nombre de leçons — dénormalisé pour affichage rapide */
    @Column(name = "nb_lecons", nullable = false)
    private int nbLecons;

    /** Durée totale cumulée des leçons en minutes */
    @Column(name = "duree_totale_minutes", nullable = false)
    private int dureeTotaleMinutes;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
JEOF
ok "ModuleJpaEntity"

cat > "$P/infrastructure/persistence/repository/LeconJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.LeconJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface LeconJpaRepository extends JpaRepository<LeconJpaEntity, UUID> {
    List<LeconJpaEntity> findByModuleIdOrderByOrdreAsc(UUID moduleId);
    int countByModuleId(UUID moduleId);

    @Query("SELECT COUNT(l) FROM LeconJpaEntity l " +
           "JOIN ModuleJpaEntity m ON l.moduleId = m.id " +
           "WHERE m.coursId = :coursId")
    int countByCoursId(UUID coursId);
}
JEOF
ok "LeconJpaRepository"

cat > "$P/infrastructure/persistence/repository/ModuleJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.ModuleJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface ModuleJpaRepository extends JpaRepository<ModuleJpaEntity, UUID> {
    List<ModuleJpaEntity> findByCoursIdOrderByOrdreAsc(UUID coursId);
    int countByCoursId(UUID coursId);
}
JEOF
ok "ModuleJpaRepository"

# =============================================================================
# 3. SessionJpaEntity — champs manquants + SessionJpaRepository conflit
# =============================================================================
sec "3/11 SessionJpaEntity champs manquants + SessionJpaRepository conflit"

cat > "$P/infrastructure/persistence/entity/SessionJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "sessions")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SessionJpaEntity {

    @Id
    private UUID id;

    @Column(name = "cours_id", nullable = false)
    private UUID coursId;

    @Column(name = "formateur_id", nullable = false)
    private UUID formateurId;

    @Column(nullable = false, length = 20)
    private String modalite; // PRESENTIEL | MEET

    /**
     * Lieu physique si PRESENTIEL, lien Google Meet si MEET.
     * Remplace les deux colonnes séparées lien_reunion + lieu.
     */
    @Column(name = "lieu_ou_lien", length = 300)
    private String lieuOuLien;

    @Column(name = "date_debut", nullable = false)
    private LocalDateTime dateDebut;

    @Column(name = "date_fin", nullable = false)
    private LocalDateTime dateFin;

    @Column(name = "capacite_max", nullable = false)
    private int capaciteMax;

    @Column(name = "places_disponibles", nullable = false)
    private int placesDisponibles;

    @Column(name = "nb_inscrits", nullable = false)
    private int nbInscrits;

    /**
     * Statut de la session :
     * PLANIFIEE → EN_COURS → TERMINEE | ANNULEE
     */
    @Column(nullable = false, length = 20)
    private String statut;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
JEOF
ok "SessionJpaEntity (remplace l'ancien)"

cat > "$P/infrastructure/persistence/repository/SessionJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.SessionJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface SessionJpaRepository extends JpaRepository<SessionJpaEntity, UUID> {

    List<SessionJpaEntity> findByCoursIdAndStatutNot(UUID coursId, String statut);

    @Query("SELECT s FROM SessionJpaEntity s " +
           "WHERE s.coursId = :coursId " +
           "AND s.statut = 'PLANIFIEE' " +
           "AND s.placesDisponibles > 0 " +
           "ORDER BY s.dateDebut ASC")
    List<SessionJpaEntity> findSessionsDisponibles(@Param("coursId") UUID coursId);

    /**
     * S20 — Détection de conflits horaires pour un formateur.
     * Vérifie si le formateur a déjà une session qui chevauche la période demandée.
     */
    @Query("SELECT COUNT(s) > 0 FROM SessionJpaEntity s " +
           "WHERE s.formateurId = :formateurId " +
           "AND s.statut NOT IN ('TERMINEE','ANNULEE') " +
           "AND s.dateDebut < :dateFin " +
           "AND s.dateFin > :dateDebut")
    boolean existsByFormateurIdAndPeriodeChevauchante(
        @Param("formateurId") UUID formateurId,
        @Param("dateDebut")   LocalDateTime dateDebut,
        @Param("dateFin")     LocalDateTime dateFin
    );

    List<SessionJpaEntity> findByFormateurId(UUID formateurId);
}
JEOF
ok "SessionJpaRepository (avec détection conflits)"

# =============================================================================
# 4. MessageCommunauteJpaEntity — nbSignalements + estMasque
# =============================================================================
sec "4/11 MessageCommunauteJpaEntity — signalement"

cat > "$P/infrastructure/persistence/entity/MessageCommunauteJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "messages_communaute")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MessageCommunauteJpaEntity {

    @Id
    private UUID id;

    @Column(name = "cours_id", nullable = false)
    private UUID coursId;

    @Column(name = "auteur_id", nullable = false)
    private UUID auteurId;

    @Column(name = "parent_id")
    private UUID parentId;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String contenu;

    @Column(name = "est_question", nullable = false)
    private boolean estQuestion;

    @Column(name = "est_resolu", nullable = false)
    private boolean estResolu;

    @Column(name = "nb_likes", nullable = false)
    private int nbLikes;

    /**
     * Nombre de signalements reçus.
     * Masquage automatique après 3 signalements (S12).
     */
    @Column(name = "nb_signalements", nullable = false)
    private int nbSignalements;

    /**
     * Message masqué en attente de modération admin.
     * Déclenché automatiquement après SEUIL_MASQUAGE_AUTO signalements.
     */
    @Column(name = "est_masque", nullable = false)
    private boolean estMasque;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
JEOF
ok "MessageCommunauteJpaEntity (avec signalement)"

# =============================================================================
# 5. CoursJpaRepository — findByStatutIn
# =============================================================================
sec "5/11 CoursJpaRepository — findByStatutIn + enrichissement"

cat > "$P/infrastructure/persistence/repository/CoursJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import com.mbem.mbemlevel.infrastructure.persistence.entity.CoursJpaEntity;
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

    /** S19 — Cours en attente de publication (admin) */
    List<CoursJpaEntity> findByStatutIn(List<String> statuts);

    /** Cours du formateur */
    List<CoursJpaEntity> findByFormateurId(UUID formateurId);
}
JEOF
ok "CoursJpaRepository (avec findByStatutIn)"

# =============================================================================
# 6. UtilisateurJpaEntity — codeParrainage
# =============================================================================
sec "6/11 UtilisateurJpaEntity — codeParrainage"

# On ne recrée pas tout — on patch uniquement en ajoutant le champ
# via un fichier patch Flyway dans V15 (déjà fait) et on documente ici
# que l'entité doit avoir le champ
cat > "$P/infrastructure/persistence/entity/UtilisateurCodeParrainagePatch.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

/**
 * PATCH NOTE — UtilisateurJpaEntity
 *
 * Ajouter ce champ dans UtilisateurJpaEntity existante :
 *
 *   @Column(name = "code_parrainage", length = 20, unique = true)
 *   private String codeParrainage;
 *
 *   public String getCodeParrainage() { return codeParrainage; }
 *   public void setCodeParrainage(String code) { this.codeParrainage = code; }
 *
 * Ce champ est ajouté par la migration V15__create_parrainage_complet.sql
 * qui contient : ALTER TABLE utilisateurs ADD COLUMN IF NOT EXISTS code_parrainage VARCHAR(20) UNIQUE;
 *
 * Généré automatiquement à l'initialisation du compte par InscrireApprenantUseCase.
 */
public final class UtilisateurCodeParrainagePatch {
    private UtilisateurCodeParrainagePatch() {}
}
JEOF
ok "Patch note UtilisateurJpaEntity — codeParrainage"

# =============================================================================
# 7. TrancheRepository (port out) + updateDateEcheance
# =============================================================================
sec "7/11 TrancheRepository port out"

cat > "$P/application/port/out/TrancheRepository.java" << 'JEOF'
package com.mbem.mbemlevel.application.port.out;

import com.mbem.mbemlevel.domain.paiement.Tranche;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TrancheRepository {
    Tranche save(Tranche tranche);
    List<Tranche> saveAll(List<Tranche> tranches);
    Optional<Tranche> findById(UUID id);
    List<Tranche> findByPaiementId(UUID paiementId);
    List<Tranche> findEnRetard();
    List<Tranche> findEcheantEntre(LocalDate debut, LocalDate fin);

    /**
     * S17 — Mettre à jour la date d'échéance de la prochaine tranche non payée
     * après accord d'un moratoire.
     */
    void updateDateEcheance(UUID paiementId, LocalDate nouvelleDateEcheance);
}
JEOF
ok "TrancheRepository (port out)"

# =============================================================================
# 8. ProgressionDomainService — vrai calcul streak + XP
# =============================================================================
sec "8/11 ProgressionDomainService — logique réelle"

cat > "$P/domain/progression/ProgressionDomainService.java" << 'JEOF'
package com.mbem.mbemlevel.domain.progression;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

/**
 * Service domaine Progression — logique métier XP, streak et badges.
 * Stateless — injecté dans les use cases.
 */
public class ProgressionDomainService {

    // ── XP ──────────────────────────────────────────────────────────────────

    /**
     * Calcule l'XP total cumulé après validation d'une leçon.
     * Le streak multiplie les XP si actif.
     *
     * @param xpActuel   XP déjà cumulé avant cette leçon
     * @param xpLecon    XP de base de la leçon
     * @param streakJours Nombre de jours consécutifs actifs
     * @return Nouvel XP total
     */
    public int calculerNouvelXP(int xpActuel, int xpLecon, int streakJours) {
        // Bonus streak : +10% par semaine complète, plafonné à +50%
        double multiplicateur = 1.0 + Math.min(0.5, (streakJours / 7) * 0.10);
        int xpAvecBonus = (int) Math.round(xpLecon * multiplicateur);
        return xpActuel + xpAvecBonus;
    }

    // ── STREAK ──────────────────────────────────────────────────────────────

    /**
     * Calcule le streak (série de jours consécutifs).
     *
     * @param dernierAcces    Date du dernier accès enregistré
     * @param streakActuel    Streak actuel en jours
     * @return Nouveau streak
     */
    public int calculerNouveauStreak(LocalDate dernierAcces, int streakActuel) {
        if (dernierAcces == null) return 1; // Premier accès
        long joursDepuis = ChronoUnit.DAYS.between(dernierAcces, LocalDate.now());

        if (joursDepuis == 0) return streakActuel;       // Même jour — pas de changement
        if (joursDepuis == 1) return streakActuel + 1;   // Lendemain — streak continue
        return 1;                                          // Gap > 1 jour — reset à 1
    }

    /**
     * Vérifie si le streak est "actif" (dernière activité aujourd'hui ou hier).
     */
    public boolean estStreakActif(LocalDate dernierAcces) {
        if (dernierAcces == null) return false;
        long joursDepuis = ChronoUnit.DAYS.between(dernierAcces, LocalDate.now());
        return joursDepuis <= 1;
    }

    // ── POURCENTAGE ─────────────────────────────────────────────────────────

    /**
     * Calcule le pourcentage de progression.
     *
     * @param nbLeconsTerminees Nombre de leçons validées (QCM >= 70%)
     * @param nbLeconsTotales   Nombre total de leçons du cours
     * @return Pourcentage de 0.0 à 100.0
     */
    public double calculerPourcentage(int nbLeconsTerminees, int nbLeconsTotales) {
        if (nbLeconsTotales <= 0) return 0.0;
        return Math.min(100.0, Math.round((double) nbLeconsTerminees / nbLeconsTotales * 100.0 * 10.0) / 10.0);
    }

    /**
     * Vérifie si le seuil de paiement est atteint.
     *
     * @param pourcentage    Pourcentage actuel (0.0–100.0)
     * @param seuilPaiement  Seuil configuré (0.01–1.0)
     * @return true si paiement requis
     */
    public boolean estSeuilAtteint(double pourcentage, double seuilPaiement) {
        return pourcentage >= (seuilPaiement * 100.0);
    }

    // ── BADGES ──────────────────────────────────────────────────────────────

    /**
     * Vérifie si un badge spécifique doit être attribué.
     *
     * @param typeBadge       Le badge à évaluer
     * @param xpTotal         XP total de l'apprenant
     * @param streakJours     Streak actuel
     * @param badgesExistants Liste des badges déjà obtenus
     * @return true si le badge doit être attribué
     */
    public boolean doitAttribuerBadge(String typeBadge, int xpTotal,
                                       int streakJours, List<String> badgesExistants) {
        if (badgesExistants.contains(typeBadge)) return false; // Déjà obtenu
        return switch (typeBadge) {
            case "XP_100"        -> xpTotal >= 100;
            case "XP_500"        -> xpTotal >= 500;
            case "XP_1000"       -> xpTotal >= 1000;
            case "XP_5000"       -> xpTotal >= 5000;
            case "STREAK_7"      -> streakJours >= 7;
            case "STREAK_30"     -> streakJours >= 30;
            case "PREMIER_COURS" -> xpTotal > 0; // A commencé au moins un cours
            default              -> false;
        };
    }

    /**
     * Retourne tous les badges à attribuer selon l'état actuel.
     */
    public List<String> calculerBadgesAAttribuer(int xpTotal, int streakJours,
                                                   List<String> badgesExistants) {
        return List.of("XP_100","XP_500","XP_1000","XP_5000",
                        "STREAK_7","STREAK_30","PREMIER_COURS")
            .stream()
            .filter(b -> doitAttribuerBadge(b, xpTotal, streakJours, badgesExistants))
            .toList();
    }
}
JEOF
ok "ProgressionDomainService (logique réelle)"

# =============================================================================
# 9. ValiderQCMUseCase — version complète avec endpoint
# =============================================================================
sec "9/11 ValiderQCMUseCase complet"

cat > "$P/api/dto/request/ValiderQCMRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;
import java.util.UUID;

/** S6 — Soumission d'une réponse QCM par l'apprenant */
public record ValiderQCMRequest(
    @NotNull  UUID   leconId,
    @NotBlank @Pattern(regexp = "[A-D]") String reponse
) {}
JEOF
ok "ValiderQCMRequest"

cat > "$P/api/dto/response/ResultatQCMResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;

/** Résultat après soumission d'un QCM — inclut la bonne réponse et l'explication */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ResultatQCMResponse(
    boolean estCorrect,
    int     scoreObtenu,
    String  bonneReponse,   // Révélée APRÈS soumission
    String  explication,    // "La bonne réponse est B car..."
    boolean leconValidee    // true si score >= 70%
) {}
JEOF
ok "ResultatQCMResponse"

cat > "$P/application/usecase/progression/ValiderQCMUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.progression;

import com.mbem.mbemlevel.api.dto.response.ResultatQCMResponse;
import com.mbem.mbemlevel.infrastructure.persistence.repository.QCMJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

/**
 * S6 — Valider la réponse d'un apprenant à un QCM.
 *
 * Règles métier :
 *  - La bonne réponse est révélée APRÈS soumission (jamais avant)
 *  - Pas de limite de tentatives
 *  - Score >= 70% requis pour valider la leçon
 *  - L'explication est toujours fournie dans la réponse
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ValiderQCMUseCase {

    private final QCMJpaRepository qcmRepo;

    @Transactional(readOnly = true)
    public ResultatQCMResponse executer(UUID leconId, String reponseApprenant, UUID apprenantId) {
        var qcm = qcmRepo.findByLeconId(leconId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:QCM_POUR_LECON:" + leconId));

        boolean estCorrect = qcm.getBonneReponse().equalsIgnoreCase(reponseApprenant.trim());
        int score = estCorrect ? qcm.getScorePoints() : 0;
        boolean leconValidee = estCorrect; // Pour un QCM simple : 1 question = 100% si correct

        log.info("[QCM] Leçon {} — apprenant {} — réponse: {} — correct: {}",
            leconId, apprenantId, reponseApprenant, estCorrect);

        return new ResultatQCMResponse(
            estCorrect,
            score,
            qcm.getBonneReponse(),      // Révélée après soumission
            qcm.getExplication(),        // "La bonne réponse est X car..."
            leconValidee
        );
    }
}
JEOF
ok "ValiderQCMUseCase (version complète)"

# =============================================================================
# 10. ENDPOINTS MANQUANTS — ajoutés dans les controllers existants
# =============================================================================
sec "10/11 Controllers — endpoints manquants"

# ── PaiementController — endpoints moratoire ──────────────────────────────────
cat > "$P/api/controller/MoratoireController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.request.*;
import com.mbem.mbemlevel.api.dto.response.ApiResponse;
import com.mbem.mbemlevel.application.usecase.paiement.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

/**
 * Gestion des moratoires (délais de paiement) — S17
 *
 * POST  /api/v1/moratoires              → Apprenant demande un délai
 * PATCH /api/v1/moratoires/{id}/decider → Admin accorde ou refuse
 */
@RestController
@RequestMapping("/api/v1/moratoires")
@Tag(name = "Moratoires", description = "Délais de paiement — S17")
@RequiredArgsConstructor
public class MoratoireController {

    private final DemanderMoratoireUseCase demanderUC;
    private final TraiterMoratoireUseCase  traiterUC;

    /** S17 — L'apprenant soumet une demande de délai */
    @PostMapping
    @PreAuthorize("hasRole('APPRENANT')")
    @Operation(summary = "Demander un moratoire (S17)")
    public ResponseEntity<ApiResponse<UUID>> demander(
            @Valid @RequestBody DemanderMoratoireRequest req,
            @AuthenticationPrincipal String userId) {
        UUID id = demanderUC.executer(req, UUID.fromString(userId));
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.ok(id,
                "Ta demande de délai a été soumise. L'équipe MbemNova te répondra rapidement."));
    }

    /** S17 — Admin accorde ou refuse un moratoire */
    @PatchMapping("/{moratoireId}/decider")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary = "Traiter une demande de moratoire — admin (S17)")
    public ResponseEntity<ApiResponse<Void>> decider(
            @PathVariable UUID moratoireId,
            @Valid @RequestBody TraiterMoratoireRequest req,
            @AuthenticationPrincipal String adminId) {
        traiterUC.executer(moratoireId, req, UUID.fromString(adminId));
        String msg = "ACCORDE".equals(req.decision())
            ? "Moratoire accordé. Le plan de paiement a été mis à jour."
            : "Moratoire refusé. L'apprenant a été notifié.";
        return ResponseEntity.ok(ApiResponse.ok(msg));
    }
}
JEOF
ok "MoratoireController (S17)"

# ── SessionController — créneaux ──────────────────────────────────────────────
cat > "$P/api/controller/CreneauController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.request.ChoisirCreneauxRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.session.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

/**
 * Gestion des créneaux horaires — S10
 *
 * GET  /api/v1/sessions/{sessionId}/creneaux → Créneaux disponibles
 * POST /api/v1/sessions/{sessionId}/creneaux → Choisir ses créneaux
 */
@RestController
@RequestMapping("/api/v1/sessions")
@Tag(name = "Créneaux", description = "Choix des créneaux horaires — S10")
@RequiredArgsConstructor
public class CreneauController {

    private final GetCreneauxSessionUseCase getCreneauxUC;
    private final ChoisirCreneauxUseCase    choisirUC;

    /** S10 — Voir les créneaux disponibles d'une session */
    @GetMapping("/{sessionId}/creneaux")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Créneaux disponibles d'une session (S10)")
    public ResponseEntity<ApiResponse<List<CreneauResponse>>> disponibles(
            @PathVariable UUID sessionId) {
        return ResponseEntity.ok(ApiResponse.ok(getCreneauxUC.executer(sessionId)));
    }

    /** S10 — L'apprenant choisit ses créneaux */
    @PostMapping("/{sessionId}/creneaux")
    @PreAuthorize("hasRole('APPRENANT')")
    @Operation(summary = "Choisir ses créneaux horaires (S10)")
    public ResponseEntity<ApiResponse<Void>> choisir(
            @PathVariable UUID sessionId,
            @Valid @RequestBody ChoisirCreneauxRequest req,
            @AuthenticationPrincipal String userId) {
        choisirUC.executer(req, UUID.fromString(userId));
        return ResponseEntity.ok(
            ApiResponse.ok("Créneaux enregistrés. Tu recevras un rappel la veille de chaque séance."));
    }
}
JEOF
ok "CreneauController (S10)"

# ── CoursController — avis + liste attente ────────────────────────────────────
cat > "$P/api/controller/AvisController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.request.LaissserAvisRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.cours.*;
import com.mbem.mbemlevel.infrastructure.persistence.entity.AvisCoursJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.AvisCoursJpaRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

/**
 * Avis sur les cours + Liste d'attente — S4
 *
 * GET  /api/v1/cours/{coursId}/avis          → Avis vérifiés
 * POST /api/v1/cours/{coursId}/avis          → Laisser un avis
 * POST /api/v1/cours/{coursId}/liste-attente → S'inscrire en liste d'attente
 */
@RestController
@RequestMapping("/api/v1/cours")
@Tag(name = "Avis & Liste d'attente", description = "Avis vérifiés et liste d'attente — S4")
@RequiredArgsConstructor
public class AvisController {

    private final LaissserAvisUseCase         laissserAvisUC;
    private final SInscrireListeAttenteUseCase listeAttenteUC;
    private final AvisCoursJpaRepository       avisRepo;

    /** S4 — Lire les avis vérifiés d'un cours */
    @GetMapping("/{coursId}/avis")
    @Operation(summary = "Avis vérifiés d'un cours (S4)")
    public ResponseEntity<ApiResponse<List<AvisCoursResponse>>> lister(
            @PathVariable UUID coursId) {
        List<AvisCoursResponse> avis = avisRepo.findByCoursId(coursId)
            .stream()
            .filter(AvisCoursJpaEntity::isEstVerifie)
            .map(a -> new AvisCoursResponse(
                a.getId(), a.getApprenantId(), a.getNote(),
                a.getCommentaire(), a.getCreatedAt()
            ))
            .toList();
        return ResponseEntity.ok(ApiResponse.ok(avis));
    }

    /** S4 — Laisser un avis (apprenant ayant >= 30% et ayant payé) */
    @PostMapping("/{coursId}/avis")
    @PreAuthorize("hasRole('APPRENANT')")
    @Operation(summary = "Laisser un avis vérifié (S4)")
    public ResponseEntity<ApiResponse<UUID>> laisserAvis(
            @PathVariable UUID coursId,
            @Valid @RequestBody LaissserAvisRequest req,
            @AuthenticationPrincipal String userId) {
        UUID id = laissserAvisUC.executer(coursId, UUID.fromString(userId), req);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.ok(id, "Merci pour ton avis — il aidera d'autres apprenants !"));
    }

    /** S4 — S'inscrire sur la liste d'attente quand toutes les sessions sont complètes */
    @PostMapping("/{coursId}/liste-attente")
    @PreAuthorize("hasRole('APPRENANT')")
    @Operation(summary = "S'inscrire sur la liste d'attente (S4)")
    public ResponseEntity<ApiResponse<Void>> listeAttente(
            @PathVariable UUID coursId,
            @RequestParam(required = false) UUID sessionId,
            @AuthenticationPrincipal String userId) {
        listeAttenteUC.executer(coursId, UUID.fromString(userId), sessionId);
        return ResponseEntity.ok(ApiResponse.ok(
            "Tu es sur la liste d'attente. Tu seras notifié dès qu'une place se libère."));
    }
}
JEOF
ok "AvisController (S4)"

# ── ParrainageController ───────────────────────────────────────────────────────
cat > "$P/api/controller/ParrainageController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.gamification.GetParrainageUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * Système de parrainage — S15
 *
 * GET /api/v1/parrainage/mon-lien    → Lien unique + message WhatsApp pré-rempli
 * GET /api/v1/parrainage/mes-filleuls → Tableau de bord filleuls + récompenses
 */
@RestController
@RequestMapping("/api/v1/parrainage")
@Tag(name = "Parrainage", description = "Système de parrainage — S15")
@PreAuthorize("hasRole('APPRENANT')")
@RequiredArgsConstructor
public class ParrainageController {

    private final GetParrainageUseCase getParrainageUC;

    /** S15 — Récupérer le lien de parrainage + message WhatsApp pré-rempli */
    @GetMapping("/mon-lien")
    @Operation(summary = "Mon lien de parrainage (S15)")
    public ResponseEntity<ApiResponse<ParrainageResponse>> monLien(
            @AuthenticationPrincipal String userId) {
        var resp = getParrainageUC.executer(java.util.UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok(resp));
    }

    /** S15 — Tableau de bord : filleuls + statuts + XP gagnés */
    @GetMapping("/mes-filleuls")
    @Operation(summary = "Mes filleuls et récompenses (S15)")
    public ResponseEntity<ApiResponse<ParrainageResponse>> mesFilleuls(
            @AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(
            ApiResponse.ok(getParrainageUC.executer(java.util.UUID.fromString(userId))));
    }
}
JEOF
ok "ParrainageController (S15)"

# ── ProgressionController — endpoint QCM ──────────────────────────────────────
cat > "$P/api/controller/QCMController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.request.ValiderQCMRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.progression.ValiderQCMUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

/**
 * Validation des QCM — S6
 *
 * POST /api/v1/qcm/lecons/{leconId}/valider → Soumettre une réponse QCM
 */
@RestController
@RequestMapping("/api/v1/qcm")
@Tag(name = "QCM", description = "Validation des QCM — S6")
@PreAuthorize("isAuthenticated()")
@RequiredArgsConstructor
public class QCMController {

    private final ValiderQCMUseCase validerUC;

    /**
     * S6 — Soumettre une réponse QCM.
     * La bonne réponse + explication sont retournées dans la réponse.
     * Pas de limite de tentatives.
     */
    @PostMapping("/lecons/{leconId}/valider")
    @Operation(summary = "Soumettre une réponse QCM (S6)")
    public ResponseEntity<ApiResponse<ResultatQCMResponse>> valider(
            @PathVariable UUID leconId,
            @Valid @RequestBody ValiderQCMRequest req,
            @AuthenticationPrincipal String userId) {
        ResultatQCMResponse resultat = validerUC.executer(
            leconId, req.reponse(), UUID.fromString(userId));
        String msg = resultat.estCorrect()
            ? "Bonne réponse ! +" + resultat.scoreObtenu() + " pts"
            : "Pas tout à fait — relis la leçon et réessaie. Tu peux retenter autant de fois que nécessaire.";
        return ResponseEntity.ok(ApiResponse.ok(resultat, msg));
    }
}
JEOF
ok "QCMController (S6)"

# ── DevoirController — mes-devoirs + tableau-bord formateur ───────────────────
cat > "$P/api/controller/DevoirListingController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

/**
 * Listing des devoirs — S11 et S22
 *
 * GET /api/v1/devoirs/mes-devoirs                        → Mes devoirs (apprenant)
 * GET /api/v1/devoirs/sessions/{sessionId}/tableau-bord  → Suivi rendus (formateur)
 */
@RestController
@RequestMapping("/api/v1/devoirs")
@Tag(name = "Devoirs listing", description = "Listing devoirs — S11, S22")
@RequiredArgsConstructor
public class DevoirListingController {

    private final DevoirJpaRepository devoirRepo;
    private final RenduJpaRepository  renduRepo;

    /** S11 — L'apprenant voit tous ses devoirs en cours */
    @GetMapping("/mes-devoirs")
    @PreAuthorize("hasRole('APPRENANT')")
    @Operation(summary = "Mes devoirs en cours (S11)")
    public ResponseEntity<ApiResponse<List<DevoirResponse>>> mesDevoirs(
            @AuthenticationPrincipal String userId) {
        // Récupérer les devoirs des sessions où l'apprenant est inscrit
        List<DevoirResponse> devoirs = renduRepo
            .findByApprenantId(UUID.fromString(userId))
            .stream()
            .map(r -> devoirRepo.findById(r.getDevoirId()))
            .filter(java.util.Optional::isPresent)
            .map(opt -> DevoirResponse.fromEntity(opt.get()))
            .toList();
        return ResponseEntity.ok(ApiResponse.ok(devoirs));
    }

    /**
     * S22 — Le formateur suit qui a rendu son devoir.
     * Retourne : soumis / pas encore soumis / en retard.
     */
    @GetMapping("/sessions/{sessionId}/tableau-bord")
    @PreAuthorize("hasAnyRole('FORMATEUR','ADMIN','SUPER_ADMIN')")
    @Operation(summary = "Tableau de bord des rendus pour une session (S22)")
    public ResponseEntity<ApiResponse<List<DevoirSuiviResponse>>> tableauBord(
            @PathVariable UUID sessionId) {
        List<DevoirSuiviResponse> suivi = devoirRepo
            .findBySessionId(sessionId)
            .stream()
            .map(d -> {
                List<RenduJpaEntity> rendus = renduRepo.findByDevoirId(d.getId());
                return new DevoirSuiviResponse(
                    d.getId(), d.getTitre(), d.getDateLimite(),
                    rendus.size(),
                    (int) rendus.stream().filter(r -> !r.isEnRetard()).count(),
                    (int) rendus.stream().filter(RenduJpaEntity::isEnRetard).count()
                );
            })
            .toList();
        return ResponseEntity.ok(ApiResponse.ok(suivi));
    }
}
JEOF
ok "DevoirListingController (S11 + S22)"

# ── TalentController — PUT profil ─────────────────────────────────────────────
cat > "$P/api/controller/TalentUpdateController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.request.MettreAJourProfilRequest;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.talent.MettreAJourProfilUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

/**
 * Mise à jour du profil talent — S14
 *
 * PUT  /api/v1/talents/me        → Mettre à jour son profil
 * POST /api/v1/talents/me/cv     → Uploader son CV (PDF)
 */
@RestController
@RequestMapping("/api/v1/talents")
@Tag(name = "Profil Talent", description = "Gestion du profil et CV — S14")
@PreAuthorize("hasRole('APPRENANT')")
@RequiredArgsConstructor
public class TalentUpdateController {

    private final MettreAJourProfilUseCase mettreAJourUC;

    /** S14 — Mettre à jour son profil talent */
    @PutMapping("/me")
    @Operation(summary = "Mettre à jour son profil (S14)")
    public ResponseEntity<ApiResponse<ProfilTalentResponse>> mettreAJour(
            @Valid @RequestBody MettreAJourProfilRequest req,
            @AuthenticationPrincipal String userId) {
        var profil = mettreAJourUC.executer(UUID.fromString(userId), req);
        return ResponseEntity.ok(ApiResponse.ok(profil, "Profil mis à jour."));
    }
}
JEOF
ok "TalentUpdateController (S14)"

# ── CommunauteController — signalement ────────────────────────────────────────
cat > "$P/api/controller/SignalementController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.response.ApiResponse;
import com.mbem.mbemlevel.application.usecase.communaute.SignalerMessageUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

/**
 * Signalement de messages communauté — S12
 *
 * POST /api/v1/communaute/messages/{messageId}/signaler
 */
@RestController
@RequestMapping("/api/v1/communaute/messages")
@Tag(name = "Communauté", description = "Signalement de messages — S12")
@PreAuthorize("isAuthenticated()")
@RequiredArgsConstructor
public class SignalementController {

    private final SignalerMessageUseCase signalerUC;

    /** S12 — Signaler un message abusif */
    @PostMapping("/{messageId}/signaler")
    @Operation(summary = "Signaler un message abusif (S12)")
    public ResponseEntity<ApiResponse<Void>> signaler(
            @PathVariable UUID messageId,
            @AuthenticationPrincipal String userId) {
        signalerUC.executer(messageId, UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok("Message signalé. L'équipe MbemNova examinera ce contenu."));
    }
}
JEOF
ok "SignalementController (S12)"

# ── UtilisateurController — RGPD (delete + export) ────────────────────────────
cat > "$P/api/controller/UtilisateurController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.response.ApiResponse;
import com.mbem.mbemlevel.application.usecase.auth.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.UUID;

/**
 * Droits RGPD utilisateurs — S28
 *
 * DELETE /api/v1/utilisateurs/me        → Supprimer son compte (droit effacement)
 * GET    /api/v1/utilisateurs/me/export → Exporter ses données (portabilité)
 */
@RestController
@RequestMapping("/api/v1/utilisateurs")
@Tag(name = "RGPD", description = "Droits des utilisateurs sur leurs données — S28")
@PreAuthorize("isAuthenticated()")
@RequiredArgsConstructor
public class UtilisateurController {

    private final SupprimerCompteUseCase              supprimerUC;
    private final ExporterDonneesPersonnellesUseCase  exporterUC;

    /**
     * S28 — Droit à l'effacement.
     * Anonymise les données personnelles, révoque toutes les sessions.
     * Les données de paiement sont conservées 10 ans (obligation légale).
     */
    @DeleteMapping("/me")
    @Operation(summary = "Supprimer son compte (S28 — droit à l'effacement)")
    public ResponseEntity<ApiResponse<Void>> supprimer(
            @AuthenticationPrincipal String userId) {
        supprimerUC.executer(UUID.fromString(userId));
        return ResponseEntity.ok(
            ApiResponse.ok("Compte supprimé. Tes données personnelles seront effacées sous 30 jours."));
    }

    /**
     * S28 — Droit à la portabilité.
     * Export JSON de toutes les données personnelles.
     */
    @GetMapping("/me/export")
    @Operation(summary = "Exporter ses données personnelles en JSON (S28)")
    public ResponseEntity<ApiResponse<Map<String, Object>>> exporter(
            @AuthenticationPrincipal String userId) {
        Map<String, Object> data = exporterUC.executer(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok(data));
    }
}
JEOF
ok "UtilisateurController (S28 — RGPD)"

# =============================================================================
# 11. SCHEDULERS MANQUANTS — S2 et S7
# =============================================================================
sec "11/11 Schedulers manquants"

cat > "$P/infrastructure/scheduler/RappelInscriptionScheduler.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.scheduler;

import com.mbem.mbemlevel.application.port.out.EmailPort;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.time.LocalDateTime;

/**
 * S2 — Relance automatique 48h après inscription si l'apprenant n'a pas commencé de cours.
 * Tourne toutes les heures — vérifie les comptes inactifs depuis 48h exactement.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class RappelInscriptionScheduler {

    private final UtilisateurJpaRepository utilisateurRepo;
    private final EmailPort                emailPort;

    @Scheduled(cron = "0 0 * * * *") // Toutes les heures
    public void rappelerInactifs48h() {
        LocalDateTime debut = LocalDateTime.now().minusHours(49);
        LocalDateTime fin   = LocalDateTime.now().minusHours(47);

        var inactifs = utilisateurRepo.findInscritsSansProgressionEntre(debut, fin);
        log.info("[SCHEDULER] Rappel 48h — {} apprenants inactifs", inactifs.size());

        for (var u : inactifs) {
            try {
                emailPort.envoyer(
                    u.getEmail(),
                    "Tu n'as pas encore commencé ton parcours MbemNova 🚀",
                    String.format("""
                        Bonjour %s,

                        Tu t'es inscrit(e) sur MbemNova il y a 2 jours, mais tu n'as pas encore\s
                        commencé ton premier cours.

                        Des centaines de compétences tech t'attendent — gratuitement jusqu'au premier seuil.
                        Lance-toi maintenant, c'est le bon moment !
                        """, u.getPrenom())
                );
            } catch (Exception e) {
                log.error("[SCHEDULER] Erreur rappel 48h pour {}: {}", u.getEmail(), e.getMessage());
            }
        }
    }
}
JEOF
ok "RappelInscriptionScheduler (S2)"

cat > "$P/infrastructure/scheduler/SeuilNonConvertiScheduler.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.scheduler;

import com.mbem.mbemlevel.application.port.out.WhatsAppPort;
import com.mbem.mbemlevel.infrastructure.persistence.repository.ProgressionJpaRepository;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.time.LocalDateTime;

/**
 * S7 — Relance WhatsApp J+1 pour les apprenants ayant atteint le seuil
 * mais n'ayant pas encore payé.
 * Tourne une fois par jour à 10h.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class SeuilNonConvertiScheduler {

    private final ProgressionJpaRepository progressionRepo;
    private final UtilisateurJpaRepository utilisateurRepo;
    private final WhatsAppPort             whatsAppPort;

    @Scheduled(cron = "0 0 10 * * *") // Tous les jours à 10h
    public void relancerNonConvertis() {
        LocalDateTime hier = LocalDateTime.now().minusDays(1);
        LocalDateTime avantHier = LocalDateTime.now().minusDays(2);

        // Apprenants ayant atteint le seuil hier (J+1) sans payer
        var nonConvertis = progressionRepo
            .findSeuilAtteintNonPayeEntre(avantHier, hier);

        log.info("[SCHEDULER] Seuil non converti — {} apprenants à relancer", nonConvertis.size());

        for (var prog : nonConvertis) {
            utilisateurRepo.findById(prog.getApprenantId()).ifPresent(u -> {
                try {
                    if (u.getTelephone() != null) {
                        whatsAppPort.envoyer(
                            u.getTelephone(),
                            String.format(
                                "Bonjour %s 👋 Tu étais à %.0f%% du cours — la suite t'attend ! " +
                                "Dis-nous si tu as des questions sur le paiement 😊 — MbemNova",
                                u.getPrenom(), prog.getPourcentage()
                            )
                        );
                    }
                } catch (Exception e) {
                    log.error("[SCHEDULER] Erreur relance non converti {}: {}", u.getEmail(), e.getMessage());
                }
            });
        }
    }
}
JEOF
ok "SeuilNonConvertiScheduler (S7)"

# DTOs manquants référencés
mkdir -p "$P/api/dto/response"
cat > "$P/api/dto/response/DevoirSuiviResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import java.util.UUID;

/** S22 — Suivi des rendus d'un devoir pour le formateur */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record DevoirSuiviResponse(
    UUID          devoirId,
    String        titre,
    LocalDateTime dateLimite,
    int           nbRendusTotal,
    int           nbATemps,
    int           nbEnRetard
) {}
JEOF
ok "DevoirSuiviResponse"

cat > "$P/api/dto/response/AvisCoursResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.LocalDateTime;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record AvisCoursResponse(
    UUID          id,
    UUID          apprenantId,
    int           note,
    String        commentaire,
    LocalDateTime createdAt
) {}
JEOF
ok "AvisCoursResponse"

echo ""
echo -e "${C_GREEN}╔══════════════════════════════════════════════════════════╗${C_NC}"
echo -e "${C_GREEN}║  ✅  s20 — Complétions finales terminées                 ║${C_NC}"
echo -e "${C_GREEN}╚══════════════════════════════════════════════════════════╝${C_NC}"
echo ""
echo "  JPA Entities   : QCMJpaEntity, LeconJpaEntity, ModuleJpaEntity,"
echo "                   SessionJpaEntity, MessageCommunauteJpaEntity"
echo "  Repositories   : QCMJpaRepository, LeconJpaRepository, ModuleJpaRepository,"
echo "                   SessionJpaRepository (+ conflit horaire),"
echo "                   CoursJpaRepository (+ findByStatutIn)"
echo "  Ports Out      : TrancheRepository (+ updateDateEcheance)"
echo "  Domain         : ProgressionDomainService (logique réelle)"
echo "  Use Cases      : ValiderQCMUseCase (complet)"
echo "  Controllers    : MoratoireController (S17), CreneauController (S10),"
echo "                   AvisController (S4), ParrainageController (S15),"
echo "                   QCMController (S6), DevoirListingController (S11+S22),"
echo "                   TalentUpdateController (S14), SignalementController (S12),"
echo "                   UtilisateurController (S28)"
echo "  Schedulers     : RappelInscriptionScheduler (S2), SeuilNonConvertiScheduler (S7)"
echo "  DTOs           : ValiderQCMRequest, ResultatQCMResponse, DevoirSuiviResponse,"
echo "                   AvisCoursResponse, CreneauResponse"
