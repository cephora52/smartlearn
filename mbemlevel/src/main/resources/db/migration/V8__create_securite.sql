-- =============================================================================
-- MbemNova V8 — Tables de sécurité
-- Refresh tokens, reset MDP, logs d'audit immuables.
-- =============================================================================

-- =============================================================================
-- REFRESH TOKENS — Rotation sécurisée
-- Le token brut est en cookie HttpOnly côté client.
-- En base : seulement le SHA-256.
-- =============================================================================
CREATE TABLE refresh_tokens (
    id              UUID        PRIMARY KEY,
    utilisateur_id  UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    -- SHA-256 du token brut — JAMAIS le token en clair
    token_hache     VARCHAR(255) NOT NULL UNIQUE,
    expire_le       TIMESTAMPTZ NOT NULL,
    -- Chaîne de rotation : chaque token pointe vers son successeur
    remplace_par    UUID        REFERENCES refresh_tokens(id),
    est_revoque     BOOLEAN     NOT NULL DEFAULT FALSE,
    ip_creation     INET,
    user_agent      VARCHAR(500),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON COLUMN refresh_tokens.token_hache IS 'SHA-256 — le token brut est transmis au client uniquement';

-- =============================================================================
-- RESET TOKENS — Réinitialisation MDP (usage unique, TTL 1h)
-- =============================================================================
CREATE TABLE reset_tokens (
    id              UUID        PRIMARY KEY,
    utilisateur_id  UUID        NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    token_hache     VARCHAR(255) NOT NULL UNIQUE,
    expire_le       TIMESTAMPTZ NOT NULL,
    est_utilise     BOOLEAN     NOT NULL DEFAULT FALSE,
    ip_demande      INET,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    utilise_le      TIMESTAMPTZ
);

COMMENT ON COLUMN reset_tokens.token_hache IS 'SHA-256 — le token brut est dans le lien email uniquement';

-- =============================================================================
-- AUDIT LOGS — Journal immuable
-- INSERT ONLY : un trigger bloque tout UPDATE et DELETE.
-- =============================================================================
CREATE TABLE audit_logs (
    id              UUID        PRIMARY KEY,
    utilisateur_id  UUID,        -- NULL pour les actions anonymes
    user_email      VARCHAR(255),-- Dénormalisé (retrouvable même si compte supprimé)
    -- Type d'action SCREAMING_SNAKE_CASE
    action          VARCHAR(100) NOT NULL,
    ressource_type  VARCHAR(50),
    ressource_id    VARCHAR(255),
    -- Contexte JSON : {ancien_role, nouveau_role, montant, ip, etc.}
    details         JSONB,
    statut          VARCHAR(20)  NOT NULL DEFAULT 'SUCCESS'
                    CHECK (statut IN ('SUCCESS','FAILURE','WARNING')),
    ip_adresse      INET,
    user_agent      VARCHAR(500),
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE audit_logs IS 'Journal audit immuable — INSERT ONLY, trigger bloque UPDATE/DELETE';

-- Trigger immuabilité audit_logs
CREATE OR REPLACE FUNCTION mbem_prevent_audit_modification()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'Les logs d audit sont immuables — modification interdite';
END;
$$;

CREATE TRIGGER trg_audit_immutable
    BEFORE UPDATE OR DELETE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION mbem_prevent_audit_modification();

-- RLS : l'application ne peut qu'insérer
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY audit_insert_only ON audit_logs FOR INSERT WITH CHECK (TRUE);
