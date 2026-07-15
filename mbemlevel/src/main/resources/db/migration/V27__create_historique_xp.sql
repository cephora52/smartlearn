-- V27__create_historique_xp.sql
-- Table pour stocker l'historique des gains de points XP pour les 7 derniers jours glissants

CREATE TABLE IF NOT EXISTS historique_xp (
    id            UUID PRIMARY KEY,
    apprenant_id  UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    xp_gagne      INTEGER NOT NULL,
    date_gain     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_historique_xp_apprenant_date ON historique_xp(apprenant_id, date_gain);
