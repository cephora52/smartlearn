-- =============================================================================
-- MbemNova V13 — Créneaux horaires des sessions (S10)
-- =============================================================================

CREATE TABLE creneaux (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID        NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    jour_semaine    VARCHAR(10) NOT NULL
                    CHECK (jour_semaine IN ('LUNDI','MARDI','MERCREDI','JEUDI','VENDREDI','SAMEDI','DIMANCHE')),
    heure_debut     TIME        NOT NULL,
    duree_minutes   SMALLINT    NOT NULL CHECK (duree_minutes > 0),
    capacite_max    SMALLINT    NOT NULL DEFAULT 30,
    places_restantes SMALLINT   NOT NULL DEFAULT 30,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Table de liaison apprenant ↔ créneau choisi
CREATE TABLE apprenant_creneaux (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    creneau_id      UUID        NOT NULL REFERENCES creneaux(id)     ON DELETE CASCADE,
    session_id      UUID        NOT NULL REFERENCES sessions(id)     ON DELETE CASCADE,
    date_choix      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (apprenant_id, creneau_id)
);

CREATE TRIGGER trg_creneaux_updated_at
    BEFORE UPDATE ON creneaux
    FOR EACH ROW EXECUTE FUNCTION mbem_update_updated_at();

CREATE INDEX idx_creneaux_session   ON creneaux(session_id);
CREATE INDEX idx_apprenant_creneaux ON apprenant_creneaux(apprenant_id);

COMMENT ON TABLE creneaux IS 'S10 — Créneaux horaires disponibles par session';
COMMENT ON TABLE apprenant_creneaux IS 'S10 — Choix de créneaux par les apprenants';
