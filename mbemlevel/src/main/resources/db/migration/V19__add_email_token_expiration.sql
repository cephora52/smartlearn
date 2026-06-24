-- =============================================================================
-- MbemNova V19 — Ajout expiration token vérification email
-- Sécurité : les tokens de confirmation email expirent après 24h
-- =============================================================================

-- Ajouter la colonne pour l'expiration du token de vérification email
ALTER TABLE utilisateurs
ADD COLUMN token_verification_email_expire_at TIMESTAMPTZ;

-- Index pour optimiser les recherches de tokens expirés
CREATE INDEX idx_utilisateurs_token_verification_expire_at
ON utilisateurs (token_verification_email_expire_at)
WHERE token_verification_email_expire_at IS NOT NULL;

-- Commentaire sur la colonne
COMMENT ON COLUMN utilisateurs.token_verification_email_expire_at
IS 'Date d''expiration du token de vérification email (24h après génération)';