-- =============================================================================
-- MbemNova V5 — Sessions de formation avec créneaux et devoirs
-- =============================================================================

CREATE TABLE sessions (
    id              UUID        PRIMARY KEY,
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE RESTRICT,
    formateur_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    titre           VARCHAR(200) NOT NULL,
    modalite        VARCHAR(20) NOT NULL CHECK (modalite IN ('PRESENTIEL','ONLINE_MEET')),
    date_debut      DATE        NOT NULL,
    date_fin        DATE        NOT NULL CHECK (date_fin >= date_debut),
    capacite_max    SMALLINT    NOT NULL CHECK (capacite_max > 0),
    nb_inscrits     SMALLINT    NOT NULL DEFAULT 0,
    lien_reunion    VARCHAR(500),  -- Google Meet / Zoom
    lieu            VARCHAR(300),  -- Adresse pour présentiel
    est_active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_sessions_updated_at
    BEFORE UPDATE ON sessions
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE session_inscriptions (
    id              UUID        PRIMARY KEY,
    session_id      UUID        NOT NULL REFERENCES sessions(id)     ON DELETE CASCADE,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    date_inscription TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (session_id, apprenant_id)
);

CREATE TABLE creneaux (
    id              UUID        PRIMARY KEY,
    session_id      UUID        NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    jour_semaine    SMALLINT    NOT NULL CHECK (jour_semaine BETWEEN 1 AND 7),
    heure_debut     TIME        NOT NULL,
    heure_fin       TIME        NOT NULL CHECK (heure_fin > heure_debut),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE devoirs (
    id              UUID        PRIMARY KEY,
    session_id      UUID        NOT NULL REFERENCES sessions(id)  ON DELETE CASCADE,
    module_id       UUID        REFERENCES modules(id)            ON DELETE SET NULL,
    titre           VARCHAR(200) NOT NULL,
    consignes       TEXT        NOT NULL,
    date_remise     TIMESTAMPTZ NOT NULL,
    est_verrouille  BOOLEAN     NOT NULL DEFAULT FALSE,
    lien_ressources VARCHAR(500),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_devoirs_updated_at
    BEFORE UPDATE ON devoirs
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE rendus (
    id              UUID        PRIMARY KEY,
    devoir_id       UUID        NOT NULL REFERENCES devoirs(id)      ON DELETE CASCADE,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    contenu         TEXT,
    lien_fichier    VARCHAR(500),
    note            SMALLINT    CHECK (note BETWEEN 0 AND 20),
    commentaire     TEXT,
    date_soumission TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_correction TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (devoir_id, apprenant_id)
);

CREATE TRIGGER trg_rendus_updated_at
    BEFORE UPDATE ON rendus
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();
