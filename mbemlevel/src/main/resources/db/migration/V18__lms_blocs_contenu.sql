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
