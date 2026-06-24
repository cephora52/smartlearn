-- =============================================================================
-- MbemNova V12 — Complétion table moratoires (S17)
-- Ajoute statut et colonnes de traitement admin
-- =============================================================================

-- Vérifier si la table moratoires existe déjà (créée partiellement dans V4)
-- Si oui, on ajoute seulement les colonnes manquantes

DO $$
BEGIN
    -- Ajouter colonne statut si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='moratoires' AND column_name='statut'
    ) THEN
        ALTER TABLE moratoires
            ADD COLUMN statut VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                CHECK (statut IN ('EN_ATTENTE','ACCORDE','REFUSE'));
    END IF;

    -- Ajouter admin_id si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='moratoires' AND column_name='admin_id'
    ) THEN
        ALTER TABLE moratoires
            ADD COLUMN admin_id UUID REFERENCES utilisateurs(id) ON DELETE SET NULL;
    END IF;

    -- Ajouter justification_refus si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='moratoires' AND column_name='justification_refus'
    ) THEN
        ALTER TABLE moratoires
            ADD COLUMN justification_refus TEXT;
    END IF;

    -- Ajouter date_decision si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='moratoires' AND column_name='date_decision'
    ) THEN
        ALTER TABLE moratoires
            ADD COLUMN date_decision TIMESTAMPTZ;
    END IF;

    -- Ajouter updated_at si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='moratoires' AND column_name='updated_at'
    ) THEN
        ALTER TABLE moratoires
            ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_moratoires_paiement ON moratoires(paiement_id);
CREATE INDEX IF NOT EXISTS idx_moratoires_statut   ON moratoires(statut) WHERE statut = 'EN_ATTENTE';

COMMENT ON TABLE moratoires IS
    'S17 — Demandes de délai de paiement. Statut EN_ATTENTE/ACCORDE/REFUSE géré par admin.';
