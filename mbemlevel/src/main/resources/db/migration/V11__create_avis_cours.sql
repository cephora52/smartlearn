-- =============================================================================
-- MbemNova V11 — Avis apprenants sur les cours (S4)
-- Règle : un apprenant doit avoir complété >= 30% du cours payé pour laisser un avis
-- Un seul avis par apprenant par cours — pas de modification après publication
-- =============================================================================

CREATE TABLE avis_cours (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE CASCADE,
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    note            SMALLINT    NOT NULL CHECK (note BETWEEN 1 AND 5),
    commentaire     TEXT,
    est_verifie     BOOLEAN     NOT NULL DEFAULT FALSE,
    -- Vérifié = apprenant a payé et complété >= 30%
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (cours_id, apprenant_id)
);

COMMENT ON TABLE avis_cours IS
    'S4 — Avis vérifiés : apprenant doit avoir >= 30% progression payée. Un seul avis par cours.';

CREATE INDEX idx_avis_cours_cours_id   ON avis_cours(cours_id);
CREATE INDEX idx_avis_cours_apprenant  ON avis_cours(apprenant_id);
