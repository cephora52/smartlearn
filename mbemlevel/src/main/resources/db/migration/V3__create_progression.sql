-- =============================================================================
-- MbemNova V3 — Progression des apprenants
-- =============================================================================

CREATE TABLE progression (
    id              UUID        PRIMARY KEY,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE CASCADE,
    pourcentage     NUMERIC(5,2) NOT NULL DEFAULT 0
                    CHECK (pourcentage BETWEEN 0 AND 100),
    est_paye        BOOLEAN     NOT NULL DEFAULT FALSE,
    xp_gagne        INTEGER     NOT NULL DEFAULT 0,
    date_debut      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_completion TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Un apprenant ne peut avoir qu'une progression par cours
    UNIQUE (apprenant_id, cours_id)
);

CREATE TRIGGER trg_progression_updated_at
    BEFORE UPDATE ON progression
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE reponses_qcm (
    id              UUID        PRIMARY KEY,
    progression_id  UUID        NOT NULL REFERENCES progression(id) ON DELETE CASCADE,
    qcm_id          UUID        NOT NULL REFERENCES qcm(id)         ON DELETE CASCADE,
    reponse_donnee  VARCHAR(5)  NOT NULL,
    est_correcte    BOOLEAN     NOT NULL,
    score           SMALLINT    NOT NULL DEFAULT 0,
    tentative       SMALLINT    NOT NULL DEFAULT 1,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE badges (
    id              UUID        PRIMARY KEY,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    type_badge      VARCHAR(50) NOT NULL,
    -- Ex: PREMIER_COURS, STREAK_7, XP_1000, CERTIFIE
    description     VARCHAR(200),
    date_obtention  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (apprenant_id, type_badge)  -- Un badge par type par apprenant
);
