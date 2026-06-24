-- =============================================================================
-- MbemNova V9 — Index de performance
-- CONVENTION : idx_{table}_{colonnes}
-- Index partiels (WHERE) : plus légers et plus rapides que les index totaux.
-- =============================================================================

-- ── Utilisateurs ─────────────────────────────────────────────────────────────

-- Email insensible à la casse (appelé à chaque connexion)
CREATE UNIQUE INDEX idx_users_email_lower
    ON utilisateurs (LOWER(email));

-- Apprenants disponibles pour l'emploi (vitrine Talents)
CREATE INDEX idx_users_disponibles
    ON utilisateurs (disponible_pour_emploi, role)
    WHERE disponible_pour_emploi = TRUE AND role = 'APPRENANT';

-- Code parrainage (recherche lors d'une inscription avec code)
CREATE UNIQUE INDEX idx_users_parrainage
    ON utilisateurs (code_parrainage)
    WHERE code_parrainage IS NOT NULL;

-- Classement XP (leaderboard gamification)
CREATE INDEX idx_users_xp_rang
    ON utilisateurs (xp_total DESC, rang_plateforme)
    WHERE role = 'APPRENANT' AND statut = 'ACTIF';

-- ── Cours ─────────────────────────────────────────────────────────────────────

-- Catalogue (filtre niveau + catégorie + actif — requête la plus fréquente)
CREATE INDEX idx_cours_catalogue
    ON cours (niveau, categorie_id, est_actif)
    WHERE est_actif = TRUE;

-- Slug pour les URLs SEO
CREATE UNIQUE INDEX idx_cours_slug
    ON cours (slug)
    WHERE slug IS NOT NULL;

-- ── Progression ───────────────────────────────────────────────────────────────

-- Index composite : dashboard apprenant (très fréquent)
CREATE INDEX idx_progression_apprenant
    ON progression (apprenant_id, est_paye, pourcentage);

-- Paiement pas encore fait + seuil atteint (conversion)
CREATE INDEX idx_progression_non_payee
    ON progression (est_paye, pourcentage)
    WHERE est_paye = FALSE;

-- ── Paiements ─────────────────────────────────────────────────────────────────

-- Paiements en retard (scheduler de relance)
CREATE INDEX idx_paiements_en_retard
    ON paiements (statut, updated_at)
    WHERE statut IN ('EN_RETARD','EN_ATTENTE');

-- ── Refresh Tokens ────────────────────────────────────────────────────────────

-- Hash (appelé à chaque refresh — doit être ultra-rapide)
CREATE UNIQUE INDEX idx_refresh_token_hache
    ON refresh_tokens (token_hache);

-- Tokens actifs par utilisateur
CREATE INDEX idx_refresh_actifs
    ON refresh_tokens (utilisateur_id, est_revoque)
    WHERE est_revoque = FALSE;

-- Expiration (cleanup scheduler)
CREATE INDEX idx_refresh_expiration
    ON refresh_tokens (expire_le)
    WHERE est_revoque = FALSE;

-- ── Reset Tokens ─────────────────────────────────────────────────────────────

CREATE UNIQUE INDEX idx_reset_token_hache
    ON reset_tokens (token_hache);

CREATE INDEX idx_reset_valides
    ON reset_tokens (utilisateur_id, est_utilise, expire_le)
    WHERE est_utilise = FALSE;

-- ── Audit Logs ────────────────────────────────────────────────────────────────

-- Historique par utilisateur
CREATE INDEX idx_audit_user_date
    ON audit_logs (utilisateur_id, created_at DESC)
    WHERE utilisateur_id IS NOT NULL;

-- Recherche par action (admin)
CREATE INDEX idx_audit_action_date
    ON audit_logs (action, created_at DESC);

-- IP suspecte (détection anomalies sécurité)
CREATE INDEX idx_audit_ip_date
    ON audit_logs (ip_adresse, created_at DESC)
    WHERE ip_adresse IS NOT NULL;

-- ── Messages Communauté ────────────────────────────────────────────────────────

CREATE INDEX idx_messages_cours_date
    ON messages_communaute (cours_id, created_at DESC)
    WHERE est_modere = FALSE;

-- ── Sessions ──────────────────────────────────────────────────────────────────

-- Sessions disponibles pour inscription
CREATE INDEX idx_sessions_disponibles
    ON sessions (cours_id, est_active, date_debut)
    WHERE est_active = TRUE;
