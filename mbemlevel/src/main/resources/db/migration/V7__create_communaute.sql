-- =============================================================================
-- MbemNova V7 — Communauté, signalements et parrainage
-- =============================================================================

CREATE TABLE messages_communaute (
    id              UUID        PRIMARY KEY,
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE CASCADE,
    auteur_id       UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    parent_id       UUID        REFERENCES messages_communaute(id)   ON DELETE CASCADE,
    contenu         TEXT        NOT NULL,
    est_question    BOOLEAN     NOT NULL DEFAULT TRUE,
    est_resolu      BOOLEAN     NOT NULL DEFAULT FALSE,
    est_modere      BOOLEAN     NOT NULL DEFAULT FALSE,
    nb_likes        INTEGER     NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_messages_updated_at
    BEFORE UPDATE ON messages_communaute
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE signalements (
    id              UUID        PRIMARY KEY,
    message_id      UUID        NOT NULL REFERENCES messages_communaute(id) ON DELETE CASCADE,
    auteur_id       UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    raison          VARCHAR(200) NOT NULL,
    statut          VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                    CHECK (statut IN ('EN_ATTENTE','TRAITE','IGNORE')),
    admin_id        UUID        REFERENCES utilisateurs(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Parrainage : lien entre parrain et filleuls
CREATE TABLE parrainages (
    id              UUID        PRIMARY KEY,
    parrain_id      UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    filleul_id      UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    code_utilise    VARCHAR(20) NOT NULL,
    statut          VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                    CHECK (statut IN ('EN_ATTENTE','ACTIF','RECOMPENSE')),
    recompense_activee BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (filleul_id)  -- Un filleul ne peut avoir qu'un seul parrain
);

-- Tirage au sort mensuel
CREATE TABLE tirages_au_sort (
    id              UUID        PRIMARY KEY,
    mois            DATE        NOT NULL UNIQUE,  -- Premier jour du mois
    gagnant_id      UUID        REFERENCES utilisateurs(id) ON DELETE SET NULL,
    nb_participants INTEGER     NOT NULL DEFAULT 0,
    prix_description VARCHAR(300),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Avis sur les cours (affichés sur la page de détail du cours)
CREATE TABLE avis_cours (
    id              UUID        PRIMARY KEY,
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE CASCADE,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    note            SMALLINT    NOT NULL CHECK (note BETWEEN 1 AND 5),
    commentaire     VARCHAR(1000),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (cours_id, apprenant_id)  -- Un seul avis par apprenant par cours
);
