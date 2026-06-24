-- =============================================================================
-- MbemNova V6 — Certificats et notifications
-- =============================================================================

CREATE TABLE certificats (
    id                  UUID        PRIMARY KEY,
    apprenant_id        UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE RESTRICT,
    cours_id            UUID        NOT NULL REFERENCES cours(id)        ON DELETE RESTRICT,
    -- Code de vérification unique (partageable publiquement)
    code_verification   VARCHAR(50) NOT NULL UNIQUE,
    lien_pdf            VARCHAR(500),
    date_emission       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (apprenant_id, cours_id)  -- Un certificat par cours par apprenant
);

COMMENT ON COLUMN certificats.code_verification IS 'Code public vérifiable sur mbemnova.com/verify/{code}';

CREATE TABLE notifications (
    id              UUID        PRIMARY KEY,
    utilisateur_id  UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    type_notif      VARCHAR(50) NOT NULL,
    canal           VARCHAR(20) NOT NULL CHECK (canal IN ('EMAIL','WHATSAPP','IN_APP')),
    titre           VARCHAR(200) NOT NULL,
    contenu         TEXT,
    est_lue         BOOLEAN     NOT NULL DEFAULT FALSE,
    date_lecture    TIMESTAMPTZ,
    -- Lien contextuel (ex: vers le cours, le certificat, la facture)
    lien_action     VARCHAR(500),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notif_user_non_lues ON notifications (utilisateur_id, est_lue)
    WHERE est_lue = FALSE;
