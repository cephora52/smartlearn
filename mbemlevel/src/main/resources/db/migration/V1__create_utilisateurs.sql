-- =============================================================================
-- MbemNova V1 — Table utilisateurs
-- Tous les rôles (apprenant, formateur, admin) dans une seule table.
-- La colonne `role` discrimine le type.
-- =============================================================================

-- Extension UUID (génération côté application, mais pgcrypto utile pour les tests)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- TABLE : utilisateurs
-- =============================================================================
CREATE TABLE utilisateurs (
    -- Identifiant UUID généré côté application (pas serial/bigserial)
    id                          UUID            PRIMARY KEY,

    -- Identité
    prenom                      VARCHAR(50)     NOT NULL,
    nom                         VARCHAR(50),
    email                       VARCHAR(255)    NOT NULL,

    -- Sécurité : JAMAIS le mot de passe en clair
    -- BCrypt hash max 72 chars effectifs (limitation BCrypt)
    mot_de_passe_hache          VARCHAR(72)     NOT NULL,
    email_verifie               BOOLEAN         NOT NULL DEFAULT FALSE,
    token_verification_email    VARCHAR(255),
    telephone                   VARCHAR(25),

    -- Rôle et statut
    role        VARCHAR(20) NOT NULL
                CHECK (role IN ('APPRENANT','FORMATEUR','ADMIN','SUPER_ADMIN')),
    statut      VARCHAR(20) NOT NULL DEFAULT 'INSCRIT'
                CHECK (statut IN ('INSCRIT','ACTIF','SUSPENDU','CERTIFIE')),

    -- Protection brute-force
    tentatives_connexion_echouees   SMALLINT    NOT NULL DEFAULT 0,
    bloque_jusqu_au                 TIMESTAMPTZ,
    derniere_connexion              TIMESTAMPTZ,

    -- ── Champs spécifiques Apprenant ────────────────────────────────────────
    ville                   VARCHAR(100),
    xp_total                INTEGER     NOT NULL DEFAULT 0 CHECK (xp_total >= 0),
    streak_jours            SMALLINT    NOT NULL DEFAULT 0 CHECK (streak_jours >= 0),
    rang_plateforme         INTEGER,
    disponible_pour_emploi  BOOLEAN     NOT NULL DEFAULT FALSE,
    lien_portfolio          VARCHAR(500),
    lien_cv                 VARCHAR(500),
    lien_linkedin           VARCHAR(500),
    lien_github             VARCHAR(500),
    bio                     VARCHAR(1000),
    code_parrainage         VARCHAR(20) UNIQUE,
    parrain_id              UUID        REFERENCES utilisateurs(id) ON DELETE SET NULL,

    -- ── Champs spécifiques Formateur ────────────────────────────────────────
    specialite              VARCHAR(200),
    biographie              TEXT,
    note_globale            NUMERIC(3,2) CHECK (note_globale >= 0 AND note_globale <= 5),

    -- ── Champs spécifiques Admin ─────────────────────────────────────────────
    niveau_acces            VARCHAR(20) CHECK (niveau_acces IN ('STANDARD','SUPER')),

    -- Audit automatique
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_utilisateurs_email UNIQUE (email)
);

COMMENT ON TABLE  utilisateurs                      IS 'Tous les utilisateurs MbemNova (apprenant, formateur, admin)';
COMMENT ON COLUMN utilisateurs.mot_de_passe_hache   IS 'Hash BCrypt cost=12 — JAMAIS en clair';
COMMENT ON COLUMN utilisateurs.tentatives_connexion_echouees IS 'Remis à 0 après connexion réussie';

-- Trigger : met à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION mbem_update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_utilisateurs_updated_at
    BEFORE UPDATE ON utilisateurs
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();
