-- =============================================================================
-- MbemNova V4 — Système de paiement avec tranches
-- =============================================================================

CREATE TABLE paiements (
    id              UUID        PRIMARY KEY,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE RESTRICT,
    montant_total   BIGINT      NOT NULL CHECK (montant_total > 0),
    montant_paye    BIGINT      NOT NULL DEFAULT 0,
    mode_paiement   VARCHAR(20) NOT NULL
                    CHECK (mode_paiement IN ('CASH','MOBILE_MONEY','ONLINE')),
    statut          VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                    CHECK (statut IN ('EN_ATTENTE','PAYE','EN_RETARD','MORATOIRE','ANNULE')),
    admin_id        UUID        REFERENCES utilisateurs(id) ON DELETE SET NULL,
    -- Accès activé après confirmation du premier paiement
    acces_active    BOOLEAN     NOT NULL DEFAULT FALSE,
    date_activation TIMESTAMPTZ,
    notes_admin     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (apprenant_id, cours_id)  -- Un seul paiement par cours par apprenant
);

CREATE TRIGGER trg_paiements_updated_at
    BEFORE UPDATE ON paiements
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE tranches (
    id              UUID        PRIMARY KEY,
    paiement_id     UUID        NOT NULL REFERENCES paiements(id) ON DELETE CASCADE,
    numero          SMALLINT    NOT NULL CHECK (numero > 0),
    montant         BIGINT      NOT NULL CHECK (montant > 0),
    date_echeance   DATE        NOT NULL,
    date_reglement  DATE,
    statut          VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                    CHECK (statut IN ('EN_ATTENTE','PAYE','EN_RETARD','MORATOIRE')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (paiement_id, numero)
);

CREATE TRIGGER trg_tranches_updated_at
    BEFORE UPDATE ON tranches
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE TABLE factures (
    id                  UUID        PRIMARY KEY,
    paiement_id         UUID        NOT NULL REFERENCES paiements(id) ON DELETE RESTRICT,
    code_verification   VARCHAR(50) NOT NULL UNIQUE,
    lien_pdf            VARCHAR(500),
    date_emission       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE moratoires (
    id                  UUID        PRIMARY KEY,
    paiement_id         UUID        NOT NULL REFERENCES paiements(id) ON DELETE CASCADE,
    raison              TEXT        NOT NULL,
    nouvelle_date       DATE        NOT NULL,
    statut              VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                        CHECK (statut IN ('EN_ATTENTE','ACCORDE','REFUSE')),
    admin_id            UUID        REFERENCES utilisateurs(id) ON DELETE SET NULL,
    commentaire_admin   TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_moratoires_updated_at
    BEFORE UPDATE ON moratoires
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();
