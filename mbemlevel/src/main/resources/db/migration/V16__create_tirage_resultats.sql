-- =============================================================================
-- MbemNova V16 — Persistance des tirages au sort mensuels (S24)
-- Loggé pour traçabilité — immuable après création
-- =============================================================================

CREATE TABLE tirages_au_sort (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    mois            VARCHAR(7)  NOT NULL UNIQUE,
    -- Format YYYY-MM, ex: 2025-01
    nb_participants INTEGER     NOT NULL DEFAULT 0,
    formation_prix  VARCHAR(200),
    -- Nom de la formation offerte comme prix
    valeur_prix     BIGINT,
    -- Valeur en FCFA
    admin_id        UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    -- Admin qui a déclenché le tirage
    effectue_le     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE gagnants_tirage (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    tirage_id       UUID        NOT NULL REFERENCES tirages_au_sort(id) ON DELETE CASCADE,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id)    ON DELETE RESTRICT,
    rang            SMALLINT    NOT NULL CHECK (rang IN (1, 2, 3)),
    -- 1 = gagnant principal, 2 et 3 = consolation
    lot_description VARCHAR(300),
    notifie         BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tirage_id, rang),
    UNIQUE (tirage_id, apprenant_id)
);

CREATE INDEX idx_gagnants_tirage_id  ON gagnants_tirage(tirage_id);
CREATE INDEX idx_gagnants_apprenant  ON gagnants_tirage(apprenant_id);

COMMENT ON TABLE tirages_au_sort IS 'S24 — Tirages mensuels — immuable après création pour traçabilité';
COMMENT ON TABLE gagnants_tirage IS 'S24 — Gagnants par tirage. Rang 1 = principal, 2-3 = consolation';
