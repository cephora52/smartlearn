-- =============================================================================
-- MbemNova V15 — Système de parrainage complet (S15)
-- =============================================================================

CREATE TABLE parrainages (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    parrain_id          UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    filleul_id          UUID        REFERENCES utilisateurs(id) ON DELETE SET NULL,
    code_parrainage     VARCHAR(20) NOT NULL UNIQUE,
    -- Lien unique mbemnova.com/ref/[code]
    statut              VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                        CHECK (statut IN ('EN_ATTENTE','ACTIF','RECOMPENSE_ACCORDEE')),
    -- ACTIF = filleul inscrit, RECOMPENSE = filleul a terminé son 1er module
    date_inscription    TIMESTAMPTZ,
    -- Date où le filleul a rejoint
    date_activation     TIMESTAMPTZ,
    -- Date où la récompense a été déclenchée (filleul termine 1er module)
    xp_parrain_credite  INTEGER     NOT NULL DEFAULT 0,
    xp_filleul_credite  INTEGER     NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_parrainages_updated_at
    BEFORE UPDATE ON parrainages
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE INDEX idx_parrainages_parrain ON parrainages(parrain_id);
CREATE INDEX idx_parrainages_code    ON parrainages(code_parrainage);
CREATE INDEX idx_parrainages_filleul ON parrainages(filleul_id) WHERE filleul_id IS NOT NULL;

-- Stocker le code de parrainage sur le compte utilisateur pour référence rapide
ALTER TABLE utilisateurs
    ADD COLUMN IF NOT EXISTS code_parrainage VARCHAR(20) UNIQUE;

COMMENT ON TABLE parrainages IS 'S15 — Suivi des parrainages et récompenses';
