-- =============================================================================
-- MbemNova V28 — Correction colonnes moratoires (S17)
-- =============================================================================

DO $$
BEGIN
    -- Renommer nouvelle_date en nouvelle_date_souhaitee si elle existe et que nouvelle_date_souhaitee n'existe pas encore
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='moratoires' AND column_name='nouvelle_date'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='moratoires' AND column_name='nouvelle_date_souhaitee'
    ) THEN
        ALTER TABLE moratoires RENAME COLUMN nouvelle_date TO nouvelle_date_souhaitee;
    END IF;

    -- Ajouter nouvelle_date_accordee si elle n'existe pas encore
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='moratoires' AND column_name='nouvelle_date_accordee'
    ) THEN
        ALTER TABLE moratoires ADD COLUMN nouvelle_date_accordee DATE;
    END IF;
END $$;
