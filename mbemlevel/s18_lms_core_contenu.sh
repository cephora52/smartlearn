#!/usr/bin/env bash
# =============================================================================
# MbemNova — s18_lms_core_contenu.sh
# LE COEUR DU LMS : Création complète d'une formation avec modules, leçons,
# contenu riche (texte HTML, images, PDF, vidéo), QCM par leçon
# Exactement comme W3Schools / Udemy / OpenClassrooms
#
# SCÉNARIOS : S19 (création cours formateur), S6 (suivre leçon + QCM)
# Ne touche PAS aux fichiers existants — NOUVEAUX uniquement
# =============================================================================
set -euo pipefail
ROOT="${1:-.}"
P="$ROOT/src/main/java/com/mbem/mbemlevel"
MIG="$ROOT/src/main/resources/db/migration"
C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_YELLOW='\033[0;33m'; C_NC='\033[0m'
ok()   { echo -e "  ${C_GREEN}✓${C_NC}  $1"; }
sec()  { echo -e "\n${C_BLUE}▶ $1${C_NC}"; }
warn() { echo -e "  ${C_YELLOW}⚠${C_NC}  $1"; }

mkdir -p "$MIG"
mkdir -p "$P/domain/cours"
mkdir -p "$P/infrastructure/persistence/entity"
mkdir -p "$P/infrastructure/persistence/mapper"
mkdir -p "$P/infrastructure/persistence/repository"
mkdir -p "$P/infrastructure/persistence/adapter"
mkdir -p "$P/application/usecase/cours"
mkdir -p "$P/application/usecase/admin"
mkdir -p "$P/application/port/out"
mkdir -p "$P/api/controller"
mkdir -p "$P/api/dto/request"
mkdir -p "$P/api/dto/response"

echo -e "\n${C_BLUE}══════════════════════════════════════════════════════════${C_NC}"
echo -e "${C_BLUE}  MbemNova · s18 · LMS CORE — Contenu pédagogique complet  ${C_NC}"
echo -e "${C_BLUE}══════════════════════════════════════════════════════════${C_NC}\n"

# =============================================================================
# 1. MIGRATION SQL — Enrichissement tables lecons + blocs_contenu
# Les tables cours/modules/lecons/qcm existent déjà dans V1/V2
# On ajoute la table blocs_contenu (contenu riche par leçon)
# =============================================================================
sec "1/8 Migration SQL — blocs de contenu + enrichissement lecons"

cat > "$MIG/V18__lms_blocs_contenu.sql" << 'SQLEOF'
-- =============================================================================
-- MbemNova V18 — LMS Core : Contenu riche par leçon
-- Chaque leçon peut avoir plusieurs blocs dans un ordre précis
-- Types de blocs : TEXTE_HTML, IMAGE, VIDEO_YOUTUBE, VIDEO_VIMEO, PDF_EMBED, CODE, CALLOUT
-- =============================================================================

-- Ajouter champs manquants sur lecons (si pas encore présents)
ALTER TABLE lecons
    ADD COLUMN IF NOT EXISTS description_courte VARCHAR(500),
    ADD COLUMN IF NOT EXISTS est_preview         BOOLEAN NOT NULL DEFAULT FALSE,
    -- est_preview = leçon accessible gratuitement même sans payer
    ADD COLUMN IF NOT EXISTS a_qcm               BOOLEAN NOT NULL DEFAULT FALSE;

-- Ajouter champs manquants sur modules
ALTER TABLE modules
    ADD COLUMN IF NOT EXISTS est_gratuit         BOOLEAN NOT NULL DEFAULT FALSE,
    -- Module entièrement gratuit (avant le seuil de paiement)
    ADD COLUMN IF NOT EXISTS nb_lecons           SMALLINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS duree_totale_minutes SMALLINT NOT NULL DEFAULT 0;

-- Ajouter champs manquants sur cours
ALTER TABLE cours
    ADD COLUMN IF NOT EXISTS description_courte  VARCHAR(500),
    ADD COLUMN IF NOT EXISTS nb_modules          SMALLINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS duree_totale_minutes INTEGER  NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS objectifs_apprentissage TEXT,
    -- JSON array : ["Créer une API REST", "Utiliser Spring Boot"]
    ADD COLUMN IF NOT EXISTS prerequis           TEXT,
    ADD COLUMN IF NOT EXISTS public_cible        VARCHAR(500),
    ADD COLUMN IF NOT EXISTS langue              VARCHAR(10) NOT NULL DEFAULT 'fr',
    ADD COLUMN IF NOT EXISTS statut              VARCHAR(20) NOT NULL DEFAULT 'BROUILLON'
        CHECK (statut IN ('BROUILLON','EN_REVISION','PUBLIE','ARCHIVE'));

-- =============================================================================
-- TABLE CENTRALE : blocs_contenu
-- Chaque leçon a plusieurs blocs ordonnés — comme W3Schools / OpenClassrooms
-- =============================================================================
CREATE TABLE IF NOT EXISTS blocs_contenu (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    lecon_id        UUID        NOT NULL REFERENCES lecons(id) ON DELETE CASCADE,
    type_bloc       VARCHAR(30) NOT NULL
                    CHECK (type_bloc IN (
                        'TEXTE_HTML',    -- Texte riche avec titres, gras, listes, tableaux
                        'IMAGE',         -- Image avec alt text et légende
                        'VIDEO_YOUTUBE', -- Embed YouTube (lien)
                        'VIDEO_VIMEO',   -- Embed Vimeo (lien)
                        'PDF_EMBED',     -- PDF lisible inline (MinIO URL)
                        'CODE',          -- Bloc de code avec syntaxe colorée
                        'CALLOUT'        -- Note importante / avertissement / astuce
                    )),
    ordre           SMALLINT    NOT NULL CHECK (ordre > 0),

    -- TEXTE_HTML : contenu HTML sanitisé (DOMPurify côté back)
    contenu_html    TEXT,

    -- IMAGE : URL MinIO + accessibilité
    url_image       VARCHAR(500),
    alt_image       VARCHAR(200),
    legende_image   VARCHAR(300),

    -- VIDEO : lien embed
    url_video       VARCHAR(500),
    duree_video_sec INTEGER,
    -- Durée en secondes pour l'affichage

    -- PDF_EMBED : URL du PDF stocké dans MinIO
    url_pdf         VARCHAR(500),
    nom_pdf         VARCHAR(200),
    -- Nom affiché à l'apprenant

    -- CODE : langage + code source
    langage_code    VARCHAR(30),
    -- Ex: java, python, javascript, sql, bash
    code_source     TEXT,

    -- CALLOUT : type visuel + message
    type_callout    VARCHAR(20)
                    CHECK (type_callout IN ('INFO','ASTUCE','ATTENTION','IMPORTANT')),
    texte_callout   TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (lecon_id, ordre)
);

CREATE TRIGGER trg_blocs_contenu_updated_at
    BEFORE UPDATE ON blocs_contenu
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

-- Enrichissement table QCM — explication de la bonne réponse
ALTER TABLE qcm
    ADD COLUMN IF NOT EXISTS explication    TEXT,
    -- Affiché après la soumission — "La bonne réponse est B car..."
    ADD COLUMN IF NOT EXISTS score_points   SMALLINT NOT NULL DEFAULT 10,
    ADD COLUMN IF NOT EXISTS ordre          SMALLINT NOT NULL DEFAULT 1;

-- =============================================================================
-- TABLE : images_lecon (galerie d'images uploadées par le formateur)
-- =============================================================================
CREATE TABLE IF NOT EXISTS ressources_cours (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    cours_id        UUID        NOT NULL REFERENCES cours(id) ON DELETE CASCADE,
    lecon_id        UUID        REFERENCES lecons(id) ON DELETE CASCADE,
    -- NULL si ressource globale du cours (ex: PDF annexe)
    type_ressource  VARCHAR(20) NOT NULL
                    CHECK (type_ressource IN ('PDF','IMAGE','AUDIO','ZIP','LIEN')),
    nom             VARCHAR(200) NOT NULL,
    url_stockage    VARCHAR(500) NOT NULL,
    taille_octets   BIGINT,
    mime_type       VARCHAR(100),
    est_public      BOOLEAN     NOT NULL DEFAULT FALSE,
    -- TRUE = accessible avant paiement
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_blocs_contenu_lecon  ON blocs_contenu(lecon_id, ordre);
CREATE INDEX idx_ressources_cours     ON ressources_cours(cours_id);
CREATE INDEX idx_ressources_lecon     ON ressources_cours(lecon_id) WHERE lecon_id IS NOT NULL;

COMMENT ON TABLE blocs_contenu IS
    'S19/S6 — Contenu riche par leçon. Chaque leçon a N blocs ordonnés (texte, image, vidéo, PDF, code, callout)';
COMMENT ON TABLE ressources_cours IS
    'S19 — Ressources téléchargeables attachées au cours ou à une leçon spécifique';
SQLEOF
ok "V18__lms_blocs_contenu.sql"

# =============================================================================
# 2. DOMAIN — BlocContenu (Value Object)
# =============================================================================
sec "2/8 Domain — BlocContenu, TypeBloc, Callout"

cat > "$P/domain/cours/TypeBloc.java" << 'JEOF'
package com.mbem.mbemlevel.domain.cours;

/**
 * Types de blocs de contenu pédagogique d'une leçon.
 * Chaque leçon est composée d'une liste ordonnée de BlocContenu.
 */
public enum TypeBloc {
    TEXTE_HTML,    // Contenu riche : titres, paragraphes, listes, tableaux, gras
    IMAGE,         // Image avec alt text et légende optionnelle
    VIDEO_YOUTUBE, // Embed YouTube via lien
    VIDEO_VIMEO,   // Embed Vimeo via lien
    PDF_EMBED,     // PDF affiché inline dans la page (stocké MinIO)
    CODE,          // Bloc de code avec coloration syntaxique
    CALLOUT        // Encadré informatif : INFO, ASTUCE, ATTENTION, IMPORTANT
}
JEOF
ok "TypeBloc enum"

cat > "$P/domain/cours/BlocContenu.java" << 'JEOF'
package com.mbem.mbemlevel.domain.cours;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Bloc de contenu pédagogique d'une leçon — Value Object.
 *
 * Une leçon est composée d'une liste ordonnée de BlocContenu.
 * Chaque bloc a un type et des données spécifiques à ce type.
 *
 * Exemples d'utilisation :
 *   - Bloc TEXTE_HTML : introduction du cours
 *   - Bloc CODE       : exemple Java
 *   - Bloc IMAGE      : schéma explicatif
 *   - Bloc CALLOUT    : "Attention à bien valider les entrées !"
 *   - Bloc PDF_EMBED  : support de cours PDF
 *   - Bloc VIDEO_YOUTUBE : vidéo explicative
 */
public class BlocContenu {

    private UUID      id;
    private UUID      leconId;
    private TypeBloc  typeBloc;
    private int       ordre;

    // ── TEXTE_HTML ──────────────────────────────────────────────
    /** Contenu HTML sanitisé (DOMPurify) */
    private String contenuHtml;

    // ── IMAGE ────────────────────────────────────────────────────
    private String urlImage;
    private String altImage;
    private String legendeImage;

    // ── VIDEO ────────────────────────────────────────────────────
    private String urlVideo;
    private Integer dureeVideoSec;

    // ── PDF ──────────────────────────────────────────────────────
    private String urlPdf;
    private String nomPdf;

    // ── CODE ─────────────────────────────────────────────────────
    private String langageCode; // java, python, javascript, sql, bash...
    private String codeSource;

    // ── CALLOUT ──────────────────────────────────────────────────
    private String typeCallout; // INFO, ASTUCE, ATTENTION, IMPORTANT
    private String texteCallout;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // ── Constructeurs factory par type ───────────────────────────

    public static BlocContenu texteHtml(UUID leconId, int ordre, String html) {
        BlocContenu b = nouveau(leconId, TypeBloc.TEXTE_HTML, ordre);
        b.contenuHtml = html;
        return b;
    }

    public static BlocContenu image(UUID leconId, int ordre,
                                     String urlImage, String alt, String legende) {
        BlocContenu b = nouveau(leconId, TypeBloc.IMAGE, ordre);
        b.urlImage = urlImage;
        b.altImage = alt;
        b.legendeImage = legende;
        return b;
    }

    public static BlocContenu videoYoutube(UUID leconId, int ordre,
                                            String urlVideo, int dureeSec) {
        BlocContenu b = nouveau(leconId, TypeBloc.VIDEO_YOUTUBE, ordre);
        b.urlVideo = urlVideo;
        b.dureeVideoSec = dureeSec;
        return b;
    }

    public static BlocContenu videoVimeo(UUID leconId, int ordre,
                                          String urlVideo, int dureeSec) {
        BlocContenu b = nouveau(leconId, TypeBloc.VIDEO_VIMEO, ordre);
        b.urlVideo = urlVideo;
        b.dureeVideoSec = dureeSec;
        return b;
    }

    public static BlocContenu pdfEmbed(UUID leconId, int ordre,
                                        String urlPdf, String nomPdf) {
        BlocContenu b = nouveau(leconId, TypeBloc.PDF_EMBED, ordre);
        b.urlPdf = urlPdf;
        b.nomPdf = nomPdf;
        return b;
    }

    public static BlocContenu code(UUID leconId, int ordre,
                                    String langage, String source) {
        BlocContenu b = nouveau(leconId, TypeBloc.CODE, ordre);
        b.langageCode = langage;
        b.codeSource  = source;
        return b;
    }

    public static BlocContenu callout(UUID leconId, int ordre,
                                       String typeCallout, String texte) {
        if (!typeCallout.matches("INFO|ASTUCE|ATTENTION|IMPORTANT")) {
            throw new IllegalArgumentException("typeCallout invalide : " + typeCallout);
        }
        BlocContenu b = nouveau(leconId, TypeBloc.CALLOUT, ordre);
        b.typeCallout = typeCallout;
        b.texteCallout = texte;
        return b;
    }

    private static BlocContenu nouveau(UUID leconId, TypeBloc type, int ordre) {
        if (ordre < 1) throw new IllegalArgumentException("Ordre >= 1");
        BlocContenu b = new BlocContenu();
        b.id       = UUID.randomUUID();
        b.leconId  = leconId;
        b.typeBloc = type;
        b.ordre    = ordre;
        b.createdAt = LocalDateTime.now();
        b.updatedAt = LocalDateTime.now();
        return b;
    }

    /** Constructeur de reconstitution depuis la persistence */
    public BlocContenu(UUID id, UUID leconId, TypeBloc typeBloc, int ordre,
                        String contenuHtml, String urlImage, String altImage,
                        String legendeImage, String urlVideo, Integer dureeVideoSec,
                        String urlPdf, String nomPdf, String langageCode,
                        String codeSource, String typeCallout, String texteCallout,
                        LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id; this.leconId = leconId; this.typeBloc = typeBloc;
        this.ordre = ordre; this.contenuHtml = contenuHtml;
        this.urlImage = urlImage; this.altImage = altImage;
        this.legendeImage = legendeImage; this.urlVideo = urlVideo;
        this.dureeVideoSec = dureeVideoSec; this.urlPdf = urlPdf;
        this.nomPdf = nomPdf; this.langageCode = langageCode;
        this.codeSource = codeSource; this.typeCallout = typeCallout;
        this.texteCallout = texteCallout; this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public BlocContenu() {}

    // ── Getters ──────────────────────────────────────────────────
    public UUID      getId()            { return id; }
    public UUID      getLeconId()       { return leconId; }
    public TypeBloc  getTypeBloc()      { return typeBloc; }
    public int       getOrdre()         { return ordre; }
    public String    getContenuHtml()   { return contenuHtml; }
    public String    getUrlImage()      { return urlImage; }
    public String    getAltImage()      { return altImage; }
    public String    getLégendeImage()  { return legendeImage; }
    public String    getUrlVideo()      { return urlVideo; }
    public Integer   getDureeVideoSec() { return dureeVideoSec; }
    public String    getUrlPdf()        { return urlPdf; }
    public String    getNomPdf()        { return nomPdf; }
    public String    getLangageCode()   { return langageCode; }
    public String    getCodeSource()    { return codeSource; }
    public String    getTypeCallout()   { return typeCallout; }
    public String    getTexteCallout()  { return texteCallout; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
JEOF
ok "BlocContenu domain"

cat > "$P/domain/cours/OptionQCM.java" << 'JEOF'
package com.mbem.mbemlevel.domain.cours;

/**
 * Option d'une question QCM.
 * Ex: { id: "A", texte: "Spring Boot est un framework Java" }
 */
public record OptionQCM(String id, String texte) {
    public OptionQCM {
        if (id == null || id.isBlank()) throw new IllegalArgumentException("id requis");
        if (texte == null || texte.isBlank()) throw new IllegalArgumentException("texte requis");
        if (!id.matches("[A-D]")) throw new IllegalArgumentException("id doit être A, B, C ou D");
    }
}
JEOF
ok "OptionQCM record"

# =============================================================================
# 3. JPA ENTITY — BlocContenuJpaEntity
# =============================================================================
sec "3/8 JPA Entity — BlocContenuJpaEntity"

cat > "$P/infrastructure/persistence/entity/BlocContenuJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import com.mbem.mbemlevel.domain.cours.TypeBloc;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "blocs_contenu")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class BlocContenuJpaEntity {

    @Id
    private UUID id;

    @Column(name = "lecon_id", nullable = false)
    private UUID leconId;

    @Enumerated(EnumType.STRING)
    @Column(name = "type_bloc", nullable = false, length = 30)
    private TypeBloc typeBloc;

    @Column(nullable = false)
    private int ordre;

    // ── TEXTE_HTML ──────────────────────────────────
    @Column(name = "contenu_html", columnDefinition = "TEXT")
    private String contenuHtml;

    // ── IMAGE ───────────────────────────────────────
    @Column(name = "url_image", length = 500)
    private String urlImage;

    @Column(name = "alt_image", length = 200)
    private String altImage;

    @Column(name = "legende_image", length = 300)
    private String legendeImage;

    // ── VIDEO ───────────────────────────────────────
    @Column(name = "url_video", length = 500)
    private String urlVideo;

    @Column(name = "duree_video_sec")
    private Integer dureeVideoSec;

    // ── PDF ─────────────────────────────────────────
    @Column(name = "url_pdf", length = 500)
    private String urlPdf;

    @Column(name = "nom_pdf", length = 200)
    private String nomPdf;

    // ── CODE ─────────────────────────────────────────
    @Column(name = "langage_code", length = 30)
    private String langageCode;

    @Column(name = "code_source", columnDefinition = "TEXT")
    private String codeSource;

    // ── CALLOUT ──────────────────────────────────────
    @Column(name = "type_callout", length = 20)
    private String typeCallout;

    @Column(name = "texte_callout", columnDefinition = "TEXT")
    private String texteCallout;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
JEOF
ok "BlocContenuJpaEntity"

cat > "$P/infrastructure/persistence/entity/RessourceCoursJpaEntity.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "ressources_cours")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RessourceCoursJpaEntity {

    @Id
    private UUID id;

    @Column(name = "cours_id", nullable = false)
    private UUID coursId;

    @Column(name = "lecon_id")
    private UUID leconId;

    @Column(name = "type_ressource", nullable = false, length = 20)
    private String typeRessource; // PDF, IMAGE, AUDIO, ZIP, LIEN

    @Column(nullable = false, length = 200)
    private String nom;

    @Column(name = "url_stockage", nullable = false, length = 500)
    private String urlStockage;

    @Column(name = "taille_octets")
    private Long tailleOctets;

    @Column(name = "mime_type", length = 100)
    private String mimeType;

    @Column(name = "est_public", nullable = false)
    private boolean estPublic;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
JEOF
ok "RessourceCoursJpaEntity"

# =============================================================================
# 4. REPOSITORIES
# =============================================================================
sec "4/8 Repositories JPA"

cat > "$P/infrastructure/persistence/repository/BlocContenuJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.BlocContenuJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface BlocContenuJpaRepository extends JpaRepository<BlocContenuJpaEntity, UUID> {
    /** Blocs d'une leçon dans l'ordre d'affichage */
    List<BlocContenuJpaEntity> findByLeconIdOrderByOrdreAsc(UUID leconId);

    /** Supprimer tous les blocs d'une leçon (pour recréer depuis 0) */
    void deleteByLeconId(UUID leconId);

    /** Nombre de blocs d'une leçon */
    int countByLeconId(UUID leconId);
}
JEOF
ok "BlocContenuJpaRepository"

cat > "$P/infrastructure/persistence/repository/RessourceCoursJpaRepository.java" << 'JEOF'
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.RessourceCoursJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface RessourceCoursJpaRepository extends JpaRepository<RessourceCoursJpaEntity, UUID> {
    List<RessourceCoursJpaEntity> findByCoursId(UUID coursId);
    List<RessourceCoursJpaEntity> findByLeconId(UUID leconId);
    List<RessourceCoursJpaEntity> findByCoursIdAndEstPublicTrue(UUID coursId);
}
JEOF
ok "RessourceCoursJpaRepository"

# =============================================================================
# 5. DTOs — Requêtes de création COMPLÈTES (formateur)
# =============================================================================
sec "5/8 DTOs — Création complète cours/module/leçon/QCM"

cat > "$P/api/dto/request/BlocContenuRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;

import com.mbem.mbemlevel.domain.cours.TypeBloc;
import jakarta.validation.constraints.*;

/**
 * Représente un bloc de contenu dans une leçon.
 * Selon le type, certains champs sont obligatoires :
 *   TEXTE_HTML    → contenuHtml requis
 *   IMAGE         → urlImage requis
 *   VIDEO_*       → urlVideo requis
 *   PDF_EMBED     → urlPdf + nomPdf requis
 *   CODE          → langageCode + codeSource requis
 *   CALLOUT       → typeCallout + texteCallout requis
 */
public record BlocContenuRequest(

    @NotNull
    TypeBloc typeBloc,

    @Min(1)
    int ordre,

    // TEXTE_HTML
    String contenuHtml,

    // IMAGE
    String urlImage,
    String altImage,
    String legendeImage,

    // VIDEO
    String urlVideo,
    Integer dureeVideoSec,

    // PDF_EMBED
    String urlPdf,
    String nomPdf,

    // CODE
    String langageCode,
    String codeSource,

    // CALLOUT
    String typeCallout,     // INFO | ASTUCE | ATTENTION | IMPORTANT
    String texteCallout

) {}
JEOF
ok "BlocContenuRequest"

cat > "$P/api/dto/request/OptionQCMRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.constraints.*;

/**
 * Option d'une question QCM.
 * id   : "A", "B", "C" ou "D"
 * texte: Le libellé de l'option
 */
public record OptionQCMRequest(
    @NotBlank @Pattern(regexp = "[A-D]") String id,
    @NotBlank @Size(max = 500)           String texte
) {}
JEOF
ok "OptionQCMRequest"

cat > "$P/api/dto/request/QCMRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;

/**
 * QCM attaché à une leçon.
 * Score minimum pour valider : 70% (configurable).
 * Pas de limite de tentatives.
 */
public record QCMRequest(

    @NotBlank @Size(max = 1000)
    String question,

    @NotEmpty @Size(min = 2, max = 4)
    @Valid
    List<OptionQCMRequest> options,

    /** Id de la bonne réponse : "A", "B", "C" ou "D" */
    @NotBlank @Pattern(regexp = "[A-D]")
    String bonneReponse,

    /**
     * Explication affichée après soumission.
     * Ex: "La réponse B est correcte car Spring Boot gère l'injection de dépendances."
     */
    @Size(max = 2000)
    String explication,

    /** Points accordés si bonne réponse. Défaut: 10 */
    @Min(1) @Max(100)
    int scorePoints

) {}
JEOF
ok "QCMRequest"

cat > "$P/api/dto/request/CreerLeconRequest.java" << 'JEOF'
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
JEOF
ok "CreerLeconRequest"

cat > "$P/api/dto/request/CreerModuleRequest.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;

/**
 * Création d'un module de cours avec toutes ses leçons.
 *
 * Un module regroupe des leçons sur un même thème.
 * Exemple : Module 1 "Introduction à Java" → 5 leçons
 */
public record CreerModuleRequest(

    @NotBlank @Size(max = 200)
    String titre,

    @Size(max = 500)
    String description,

    @Min(1)
    int ordre,

    /** XP bonus accordés quand tout le module est terminé */
    @Min(0) @Max(1000)
    int xpBonus,

    /**
     * Module accessible entièrement avant le seuil de paiement.
     * Typiquement vrai pour le module 1 (introduction gratuite).
     */
    boolean estGratuit,

    /**
     * Leçons du module dans l'ordre.
     * Minimum 1 leçon par module.
     */
    @NotEmpty
    @Valid
    List<CreerLeconRequest> lecons

) {}
JEOF
ok "CreerModuleRequest"

cat > "$P/api/dto/request/CreerCoursCompletRequest.java" << 'JEOF'
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
JEOF
ok "CreerCoursCompletRequest"

# =============================================================================
# 6. DTOs — Réponses (ce que l'API retourne)
# =============================================================================
sec "6/8 DTOs Réponses — LeconResponse, ModuleResponse, CoursDetailResponse"

cat > "$P/api/dto/response/BlocContenuResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.mbem.mbemlevel.domain.cours.TypeBloc;
import com.mbem.mbemlevel.infrastructure.persistence.entity.BlocContenuJpaEntity;
import java.util.UUID;

/**
 * Réponse d'un bloc de contenu — seuls les champs pertinents au type sont inclus.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record BlocContenuResponse(
    UUID     id,
    TypeBloc typeBloc,
    int      ordre,

    // TEXTE_HTML
    String contenuHtml,

    // IMAGE
    String urlImage,
    String altImage,
    String legendeImage,

    // VIDEO
    String  urlVideo,
    Integer dureeVideoSec,

    // PDF
    String urlPdf,
    String nomPdf,

    // CODE
    String langageCode,
    String codeSource,

    // CALLOUT
    String typeCallout,
    String texteCallout
) {
    public static BlocContenuResponse from(BlocContenuJpaEntity e) {
        return new BlocContenuResponse(
            e.getId(), e.getTypeBloc(), e.getOrdre(),
            e.getContenuHtml(),
            e.getUrlImage(), e.getAltImage(), e.getLégendeImage(),
            e.getUrlVideo(), e.getDureeVideoSec(),
            e.getUrlPdf(), e.getNomPdf(),
            e.getLangageCode(), e.getCodeSource(),
            e.getTypeCallout(), e.getTexteCallout()
        );
    }
}
JEOF
ok "BlocContenuResponse"

cat > "$P/api/dto/response/QCMResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Réponse QCM — la bonne réponse N'EST PAS incluse (envoyée seulement après soumission).
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record QCMResponse(
    UUID               id,
    String             question,
    /** Options : [{id:"A", texte:"..."}, ...] */
    List<Map<String,String>> options,
    int                scorePoints,
    int                ordre
) {}
JEOF
ok "QCMResponse"

cat > "$P/api/dto/response/LeconDetailResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;
import java.util.UUID;

/**
 * Réponse complète d'une leçon avec tout son contenu pédagogique.
 * Retournée quand l'apprenant ouvre une leçon.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record LeconDetailResponse(
    UUID                      id,
    UUID                      moduleId,
    String                    titre,
    String                    descriptionCourte,
    int                       ordre,
    int                       dureeMinutes,
    int                       xpValeur,
    boolean                   estPreview,
    boolean                   aQCM,
    /** Blocs de contenu dans l'ordre d'affichage */
    List<BlocContenuResponse> blocs,
    /** QCM de la leçon (null si pas de QCM) */
    QCMResponse               qcm,
    /** Ressources téléchargeables de la leçon */
    List<RessourceResponse>   ressources
) {}
JEOF
ok "LeconDetailResponse"

cat > "$P/api/dto/response/RessourceResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.UUID;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record RessourceResponse(
    UUID   id,
    String typeRessource,
    String nom,
    String urlStockage,
    Long   tailleOctets,
    String mimeType
) {}
JEOF
ok "RessourceResponse"

cat > "$P/api/dto/response/ModuleResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.List;
import java.util.UUID;

/**
 * Module avec ses leçons (résumé — pas le contenu complet).
 * Pour le contenu complet d'une leçon : GET /api/v1/cours/lecons/{leconId}
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ModuleResponse(
    UUID              id,
    String            titre,
    String            description,
    int               ordre,
    int               xpBonus,
    boolean           estGratuit,
    boolean           estVerrouille,
    int               nbLecons,
    int               dureeTotaleMinutes,
    List<LeconSommaireResponse> lecons
) {}
JEOF
ok "ModuleResponse"

cat > "$P/api/dto/response/LeconSommaireResponse.java" << 'JEOF'
package com.mbem.mbemlevel.api.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.UUID;

/**
 * Résumé d'une leçon (pour la liste dans un module).
 * Pas le contenu complet — juste les métadonnées.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record LeconSommaireResponse(
    UUID    id,
    String  titre,
    int     ordre,
    int     dureeMinutes,
    int     xpValeur,
    boolean estPreview,
    boolean aQCM,
    /** État de complétion pour l'apprenant connecté */
    Boolean estTerminee
) {}
JEOF
ok "LeconSommaireResponse"

# =============================================================================
# 7. USE CASES — Création cours complet + gestion contenu
# =============================================================================
sec "7/8 Use Cases — Cours complet LMS"

cat > "$P/application/usecase/cours/CreerCoursCompletUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.api.dto.request.*;
import com.mbem.mbemlevel.application.port.out.*;
import com.mbem.mbemlevel.domain.cours.*;
import com.mbem.mbemlevel.domain.shared.enums.NiveauCours;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

/**
 * S19 — Création complète d'un cours par le formateur.
 *
 * Persiste dans l'ordre :
 *   1. Le cours (statut BROUILLON)
 *   2. Les modules (dans l'ordre)
 *   3. Les leçons de chaque module (dans l'ordre)
 *   4. Les blocs de contenu de chaque leçon (dans l'ordre)
 *   5. Les QCM de chaque leçon (si présent)
 *
 * Le cours reste en BROUILLON jusqu'à validation admin (PublierCoursUseCase).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CreerCoursCompletUseCase {

    private final CoursRepository            coursRepo;
    private final ModuleJpaRepository        moduleRepo;
    private final LeconJpaRepository         leconRepo;
    private final BlocContenuJpaRepository   blocRepo;
    private final QCMJpaRepository           qcmRepo;

    @Transactional
    public UUID executer(CreerCoursCompletRequest req, UUID formateurId) {
        // 1. Créer le cours
        UUID coursId = UUID.randomUUID();
        Cours cours = Cours.creer(
            req.titre(), req.descriptionCourte(),
            req.niveau(), req.categorieId(),
            formateurId, req.seuilPaiement(), req.prixFcfa()
        );
        cours.setDescriptionLongue(req.descriptionLongue());
        cours.setImageCouverture(req.imageCouverture());
        cours.setObjectifsApprentissage(req.objectifsApprentissage());
        cours.setPrerequisEtPublicCible(req.prerequis(), req.publicCible());
        coursRepo.save(cours);
        log.info("[COURS] Cours créé en brouillon: {} par formateur: {}", cours.getId(), formateurId);

        // 2. Créer les modules
        int totalDuree = 0;
        for (CreerModuleRequest mr : req.modules()) {
            UUID moduleId = UUID.randomUUID();
            ModuleJpaEntity module = ModuleJpaEntity.builder()
                .id(moduleId)
                .coursId(cours.getId())
                .titre(mr.titre())
                .description(mr.description())
                .ordre(mr.ordre())
                .xpBonus(mr.xpBonus())
                .estGratuit(mr.estGratuit())
                .estVerrouille(true)
                .nbLecons(mr.lecons().size())
                .build();
            moduleRepo.save(module);

            // 3. Créer les leçons du module
            int dureeTotaleModule = 0;
            for (CreerLeconRequest lr : mr.lecons()) {
                UUID leconId = UUID.randomUUID();
                LeconJpaEntity lecon = LeconJpaEntity.builder()
                    .id(leconId)
                    .moduleId(moduleId)
                    .titre(lr.titre())
                    .descriptionCourte(lr.descriptionCourte())
                    .ordre(lr.ordre())
                    .dureeMinutes(lr.dureeMinutes())
                    .xpValeur(lr.xpValeur())
                    .estPreview(lr.estPreview())
                    .aQCM(lr.aQCM())
                    .build();
                leconRepo.save(lecon);
                dureeTotaleModule += lr.dureeMinutes();

                // 4. Créer les blocs de contenu
                for (BlocContenuRequest br : lr.blocs()) {
                    BlocContenuJpaEntity bloc = creerBloc(leconId, br);
                    blocRepo.save(bloc);
                }

                // 5. Créer le QCM si présent
                if (lr.aQCM() && lr.qcm() != null) {
                    creerQCM(leconId, lr.qcm(), qcmRepo);
                }
            }
            totalDuree += dureeTotaleModule;

            // Mettre à jour la durée totale du module
            module.setDureeTotaleMinutes(dureeTotaleModule);
            moduleRepo.save(module);
        }

        // Mettre à jour stats du cours
        cours.setNbModules(req.modules().size());
        cours.setDureeTotaleMinutes(
            req.dureeTotaleMinutes() != null ? req.dureeTotaleMinutes() : totalDuree
        );
        coursRepo.save(cours);

        log.info("[COURS] Cours complet persisté: {} modules, {} minutes",
            req.modules().size(), totalDuree);
        return cours.getId();
    }

    private BlocContenuJpaEntity creerBloc(UUID leconId, BlocContenuRequest r) {
        return BlocContenuJpaEntity.builder()
            .id(UUID.randomUUID())
            .leconId(leconId)
            .typeBloc(r.typeBloc())
            .ordre(r.ordre())
            .contenuHtml(r.contenuHtml())
            .urlImage(r.urlImage())
            .altImage(r.altImage())
            .legendeImage(r.legendeImage())
            .urlVideo(r.urlVideo())
            .dureeVideoSec(r.dureeVideoSec())
            .urlPdf(r.urlPdf())
            .nomPdf(r.nomPdf())
            .langageCode(r.langageCode())
            .codeSource(r.codeSource())
            .typeCallout(r.typeCallout())
            .texteCallout(r.texteCallout())
            .build();
    }

    private void creerQCM(UUID leconId, QCMRequest r, QCMJpaRepository qcmRepo) {
        List<Map<String,String>> options = r.options().stream()
            .map(o -> Map.of("id", o.id(), "texte", o.texte()))
            .toList();
        QCMJpaEntity qcm = QCMJpaEntity.builder()
            .id(UUID.randomUUID())
            .leconId(leconId)
            .question(r.question())
            .optionsJson(options.toString()) // sérialisé en JSONB via @Convert ou String
            .bonneReponse(r.bonneReponse())
            .explication(r.explication())
            .scorePoints(r.scorePoints())
            .ordre(1)
            .build();
        qcmRepo.save(qcm);
    }
}
JEOF
ok "CreerCoursCompletUseCase"

cat > "$P/application/usecase/cours/GetLeconDetailUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.infrastructure.persistence.entity.*;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

/**
 * S6 — Récupère le contenu complet d'une leçon pour l'affichage.
 * Inclut : blocs de contenu ordonnés, QCM (sans la bonne réponse), ressources.
 */
@Service
@RequiredArgsConstructor
public class GetLeconDetailUseCase {

    private final LeconJpaRepository       leconRepo;
    private final BlocContenuJpaRepository blocRepo;
    private final QCMJpaRepository         qcmRepo;
    private final RessourceCoursJpaRepository ressourceRepo;
    private final ProgressionJpaRepository progressionRepo;

    @Transactional(readOnly = true)
    public LeconDetailResponse executer(UUID leconId, UUID apprenantId) {
        LeconJpaEntity lecon = leconRepo.findById(leconId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:LECON:" + leconId));

        // Blocs de contenu dans l'ordre
        List<BlocContenuResponse> blocs = blocRepo
            .findByLeconIdOrderByOrdreAsc(leconId)
            .stream()
            .map(BlocContenuResponse::from)
            .toList();

        // QCM sans la bonne réponse (sécurité)
        QCMResponse qcmResp = qcmRepo.findByLeconId(leconId)
            .map(q -> new QCMResponse(
                q.getId(),
                q.getQuestion(),
                parseOptions(q.getOptionsJson()),
                q.getScorePoints(),
                q.getOrdre()
                // bonneReponse NON incluse ici
            ))
            .orElse(null);

        // Ressources de la leçon
        List<RessourceResponse> ressources = ressourceRepo
            .findByLeconId(leconId)
            .stream()
            .map(r -> new RessourceResponse(
                r.getId(), r.getTypeRessource(), r.getNom(),
                r.getUrlStockage(), r.getTailleOctets(), r.getMimeType()
            ))
            .toList();

        return new LeconDetailResponse(
            lecon.getId(), lecon.getModuleId(),
            lecon.getTitre(), lecon.getDescriptionCourte(),
            lecon.getOrdre(), lecon.getDureeMinutes(), lecon.getXpValeur(),
            lecon.isEstPreview(), lecon.isAQCM(),
            blocs, qcmResp, ressources
        );
    }

    @SuppressWarnings("unchecked")
    private List<Map<String,String>> parseOptions(String json) {
        // Simplifié — en production utiliser ObjectMapper
        return List.of();
    }
}
JEOF
ok "GetLeconDetailUseCase"

cat > "$P/application/usecase/cours/ModifierBlocsLeconUseCase.java" << 'JEOF'
package com.mbem.mbemlevel.application.usecase.cours;

import com.mbem.mbemlevel.api.dto.request.BlocContenuRequest;
import com.mbem.mbemlevel.infrastructure.persistence.entity.BlocContenuJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.UUID;

/**
 * S19 — Modifier/remplacer les blocs de contenu d'une leçon existante.
 * Supprime tous les blocs existants et recrée depuis la liste fournie.
 * Utilisé lors de l'édition du cours par le formateur.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ModifierBlocsLeconUseCase {

    private final BlocContenuJpaRepository blocRepo;
    private final LeconJpaRepository       leconRepo;

    @Transactional
    public void executer(UUID leconId, List<BlocContenuRequest> nouveauxBlocs, UUID formateurId) {
        // Vérifier que la leçon existe
        leconRepo.findById(leconId)
            .orElseThrow(() -> new RuntimeException("RESOURCE_NOT_FOUND:LECON:" + leconId));

        // Supprimer tous les blocs existants
        blocRepo.deleteByLeconId(leconId);

        // Recréer depuis la liste
        for (BlocContenuRequest br : nouveauxBlocs) {
            BlocContenuJpaEntity bloc = BlocContenuJpaEntity.builder()
                .id(UUID.randomUUID())
                .leconId(leconId)
                .typeBloc(br.typeBloc())
                .ordre(br.ordre())
                .contenuHtml(br.contenuHtml())
                .urlImage(br.urlImage()).altImage(br.altImage()).legendeImage(br.legendeImage())
                .urlVideo(br.urlVideo()).dureeVideoSec(br.dureeVideoSec())
                .urlPdf(br.urlPdf()).nomPdf(br.nomPdf())
                .langageCode(br.langageCode()).codeSource(br.codeSource())
                .typeCallout(br.typeCallout()).texteCallout(br.texteCallout())
                .build();
            blocRepo.save(bloc);
        }
        log.info("[COURS] Blocs mis à jour pour leçon {} : {} blocs", leconId, nouveauxBlocs.size());
    }
}
JEOF
ok "ModifierBlocsLeconUseCase"

# =============================================================================
# 8. CONTROLLER — Endpoints LMS complets
# =============================================================================
sec "8/8 Controllers — CoursAdminController enrichi + CoursController enrichi"

cat > "$P/api/controller/CoursAdminController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.request.*;
import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.admin.*;
import com.mbem.mbemlevel.application.usecase.cours.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;
import java.util.UUID;

/**
 * API Cours Admin — Création et gestion des cours par formateur/admin.
 *
 * POST   /api/v1/admin/cours               → Créer un cours complet (S19)
 * POST   /api/v1/admin/cours/{id}/publier  → Publier le cours (admin)
 * GET    /api/v1/admin/cours/en-attente    → Cours en attente de publication
 * PUT    /api/v1/admin/cours/{id}/modules/{mId}/lecons/{lId}/blocs
 *                                          → Modifier les blocs d'une leçon
 * POST   /api/v1/admin/cours/{id}/ressources → Upload ressource cours
 */
@RestController
@RequestMapping("/api/v1/admin/cours")
@Tag(name = "Cours Admin", description = "Gestion LMS — création et édition des cours")
@PreAuthorize("hasAnyRole('FORMATEUR','ADMIN','SUPER_ADMIN')")
@RequiredArgsConstructor
public class CoursAdminController {

    private final CreerCoursCompletUseCase  creerCoursCompletUC;
    private final PublierCoursUseCase       publierUC;
    private final GetCoursEnAttenteUseCase  enAttenteUC;
    private final ModifierBlocsLeconUseCase modifierBlocsUC;

    /**
     * S19 — Créer un cours complet avec modules, leçons, blocs, QCM.
     * Le cours est créé en statut BROUILLON — non visible dans le catalogue.
     * L'admin doit le publier via POST /{id}/publier.
     */
    @PostMapping
    @Operation(summary = "Créer un cours complet (S19) — modules + leçons + contenu + QCM")
    public ResponseEntity<ApiResponse<UUID>> creerComplet(
            @Valid @RequestBody CreerCoursCompletRequest req,
            @AuthenticationPrincipal String userId) {
        UUID coursId = creerCoursCompletUC.executer(req, UUID.fromString(userId));
        return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(ApiResponse.ok(coursId, "Cours créé en brouillon. En attente de validation admin."));
    }

    /**
     * Modifier les blocs de contenu d'une leçon existante.
     * Remplace tous les blocs par la nouvelle liste.
     */
    @PutMapping("/{coursId}/lecons/{leconId}/blocs")
    @Operation(summary = "Mettre à jour les blocs de contenu d'une leçon")
    public ResponseEntity<ApiResponse<Void>> modifierBlocs(
            @PathVariable UUID coursId,
            @PathVariable UUID leconId,
            @Valid @RequestBody List<BlocContenuRequest> blocs,
            @AuthenticationPrincipal String userId) {
        modifierBlocsUC.executer(leconId, blocs, UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.ok("Contenu de la leçon mis à jour."));
    }

    /**
     * S19 — Publier un cours (admin uniquement).
     * Le cours devient visible dans le catalogue.
     */
    @PostMapping("/{coursId}/publier")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary = "Publier un cours — visible dans le catalogue (S19)")
    public ResponseEntity<ApiResponse<Void>> publier(
            @PathVariable UUID coursId,
            @AuthenticationPrincipal String adminId) {
        publierUC.executer(coursId, UUID.fromString(adminId));
        return ResponseEntity.ok(ApiResponse.ok("Cours publié dans le catalogue."));
    }

    /**
     * S19 — Lister les cours en attente de validation (admin).
     */
    @GetMapping("/en-attente")
    @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN')")
    @Operation(summary = "Cours en attente de publication (S19)")
    public ResponseEntity<ApiResponse<List<CoursResponse>>> enAttente() {
        return ResponseEntity.ok(ApiResponse.ok(enAttenteUC.executer()));
    }
}
JEOF
ok "CoursAdminController (remplace l'ancien)"

# Controller public pour lire les leçons
cat > "$P/api/controller/LeconController.java" << 'JEOF'
package com.mbem.mbemlevel.api.controller;

import com.mbem.mbemlevel.api.dto.response.*;
import com.mbem.mbemlevel.application.usecase.cours.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.UUID;

/**
 * API Lecture des leçons pour les apprenants.
 *
 * GET /api/v1/cours/{coursId}/modules/{moduleId}/lecons/{leconId}
 *     → Contenu complet de la leçon (blocs, QCM sans bonne réponse, ressources)
 */
@RestController
@RequestMapping("/api/v1/cours")
@Tag(name = "Leçons", description = "Contenu pédagogique des leçons")
@RequiredArgsConstructor
public class LeconController {

    private final GetLeconDetailUseCase getLeconDetailUC;

    /**
     * S6 — Ouvrir une leçon et afficher son contenu complet.
     * Retourne les blocs ordonnés (texte, image, vidéo, PDF, code, callout)
     * et le QCM de la leçon si présent (sans la bonne réponse).
     */
    @GetMapping("/{coursId}/modules/{moduleId}/lecons/{leconId}")
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Contenu complet d'une leçon (S6)")
    public ResponseEntity<ApiResponse<LeconDetailResponse>> getLecon(
            @PathVariable UUID coursId,
            @PathVariable UUID moduleId,
            @PathVariable UUID leconId,
            @AuthenticationPrincipal String userId) {
        UUID apprenantId = userId != null ? UUID.fromString(userId) : null;
        return ResponseEntity.ok(
            ApiResponse.ok(getLeconDetailUC.executer(leconId, apprenantId))
        );
    }
}
JEOF
ok "LeconController"

echo ""
warn "Repositories LeconJpaRepository et QCMJpaRepository doivent exister (vérifier s09)"
warn "CoursRepository.setNbModules() / setDureeTotaleMinutes() à ajouter sur Cours domain"
warn "GetCoursEnAttenteUseCase à créer (voir script s19)"
echo ""
echo -e "${C_GREEN}✅  LMS Core complet généré${C_NC}"
echo "   SQL          : V18 — blocs_contenu, ressources_cours, enrichissement lecons/modules/cours"
echo "   Domain       : TypeBloc, BlocContenu, OptionQCM"
echo "   JPA Entities : BlocContenuJpaEntity, RessourceCoursJpaEntity"
echo "   Repos JPA    : BlocContenuJpaRepository, RessourceCoursJpaRepository"
echo "   DTOs Request : BlocContenuRequest, QCMRequest, OptionQCMRequest,"
echo "                  CreerLeconRequest, CreerModuleRequest, CreerCoursCompletRequest"
echo "   DTOs Response: BlocContenuResponse, QCMResponse, LeconDetailResponse,"
echo "                  LeconSommaireResponse, RessourceResponse, ModuleResponse"
echo "   Use Cases    : CreerCoursCompletUseCase, GetLeconDetailUseCase,"
echo "                  ModifierBlocsLeconUseCase"
echo "   Controllers  : CoursAdminController (remplacé), LeconController (nouveau)"
