-- =============================================================================
-- MbemNova V2 — Cours, modules, leçons, QCM, catégories
-- =============================================================================

CREATE TABLE categories (
    id          UUID        PRIMARY KEY,
    nom         VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(500),
    icone       VARCHAR(100),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE cours (
    id                  UUID        PRIMARY KEY,
    titre               VARCHAR(200) NOT NULL,
    description         TEXT,
    niveau              VARCHAR(20)  NOT NULL CHECK (niveau IN ('DEBUTANT','INTERMEDIAIRE','AVANCE')),
    categorie_id        UUID         REFERENCES categories(id) ON DELETE SET NULL,
    formateur_id        UUID         REFERENCES utilisateurs(id) ON DELETE SET NULL,
    -- Pourcentage du cours (0.0 à 1.0) après lequel le paiement est demandé
    seuil_paiement      NUMERIC(3,2) NOT NULL DEFAULT 0.30
                        CHECK (seuil_paiement > 0 AND seuil_paiement <= 1),
    prix_fcfa           BIGINT       NOT NULL DEFAULT 0 CHECK (prix_fcfa >= 0),
    est_actif           BOOLEAN      NOT NULL DEFAULT TRUE,
    -- Meta SEO
    slug                VARCHAR(250) UNIQUE,
    image_couverture    VARCHAR(500),
    -- Statistiques dénormalisées (mise à jour par trigger ou scheduler)
    nb_apprenants       INTEGER      NOT NULL DEFAULT 0,
    note_moyenne        NUMERIC(3,2) CHECK (note_moyenne >= 0 AND note_moyenne <= 5),
    nb_avis             INTEGER      NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_cours_updated_at
    BEFORE UPDATE ON cours
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE modules (
    id              UUID        PRIMARY KEY,
    cours_id        UUID        NOT NULL REFERENCES cours(id) ON DELETE CASCADE,
    titre           VARCHAR(200) NOT NULL,
    description     VARCHAR(500),
    ordre           SMALLINT    NOT NULL CHECK (ordre > 0),
    est_verrouille  BOOLEAN     NOT NULL DEFAULT TRUE,
    xp_bonus        SMALLINT    NOT NULL DEFAULT 100,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (cours_id, ordre)
);

CREATE TRIGGER trg_modules_updated_at
    BEFORE UPDATE ON modules
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE lecons (
    id              UUID        PRIMARY KEY,
    module_id       UUID        NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    titre           VARCHAR(200) NOT NULL,
    contenu_texte   TEXT,
    lien_pdf        VARCHAR(500),
    lien_video      VARCHAR(500),
    ordre           SMALLINT    NOT NULL CHECK (ordre > 0),
    duree_minutes   SMALLINT    CHECK (duree_minutes > 0),
    xp_valeur       SMALLINT    NOT NULL DEFAULT 25,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (module_id, ordre)
);

CREATE TRIGGER trg_lecons_updated_at
    BEFORE UPDATE ON lecons
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE qcm (
    id              UUID        PRIMARY KEY,
    lecon_id        UUID        NOT NULL REFERENCES lecons(id) ON DELETE CASCADE,
    question        TEXT        NOT NULL,
    -- Options JSON : [{"id":"A","texte":"..."},{"id":"B","texte":"..."}]
    options         JSONB       NOT NULL,
    bonne_reponse   VARCHAR(5)  NOT NULL,
    est_obligatoire BOOLEAN     NOT NULL DEFAULT TRUE,
    score_min_pct   SMALLINT    NOT NULL DEFAULT 70
                    CHECK (score_min_pct BETWEEN 0 AND 100),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
