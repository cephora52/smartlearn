-- =============================================================================
-- MbemNova V17 — Liste d'attente pour les sessions complètes (S4)
-- =============================================================================

CREATE TABLE liste_attente (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    apprenant_id    UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    session_id      UUID        REFERENCES sessions(id)              ON DELETE CASCADE,
    cours_id        UUID        NOT NULL REFERENCES cours(id)        ON DELETE CASCADE,
    -- session_id peut être NULL si l'attente concerne n'importe quelle session du cours
    statut          VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE'
                    CHECK (statut IN ('EN_ATTENTE','NOTIFIE','INSCRIT','ANNULE')),
    date_inscription TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_notification TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (apprenant_id, cours_id)
    -- Un apprenant ne peut être sur liste d'attente qu'une fois par cours
);

CREATE INDEX idx_liste_attente_cours   ON liste_attente(cours_id) WHERE statut = 'EN_ATTENTE';
CREATE INDEX idx_liste_attente_session ON liste_attente(session_id) WHERE session_id IS NOT NULL;

COMMENT ON TABLE liste_attente IS 'S4 — Liste d''attente quand toutes les sessions sont complètes';
