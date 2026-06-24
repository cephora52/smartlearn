-- =============================================================================
-- MbemNova V20 — Ajout des colonnes de signalement pour le masquage automatique
-- =============================================================================

ALTER TABLE messages_communaute
ADD COLUMN nb_signalements INTEGER NOT NULL DEFAULT 0,
ADD COLUMN est_masque BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN messages_communaute.nb_signalements IS 'Nombre de signalements reçus par ce message';
COMMENT ON COLUMN messages_communaute.est_masque IS 'Indique si le message est masqué suite à des signalements abusifs';
