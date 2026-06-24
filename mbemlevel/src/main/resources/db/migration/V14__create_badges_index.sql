-- =============================================================================
-- MbemNova V14 — Index et complétions pour badges (S6, S13)
-- La table badges est dans V3 — on ajoute seulement les index manquants
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_badges_apprenant ON badges(apprenant_id);
CREATE INDEX IF NOT EXISTS idx_badges_type      ON badges(type_badge);

-- Types de badges autorisés (documentation)
COMMENT ON TABLE badges IS
    'S6/S13 — Badges gamification. Types: PREMIER_COURS, MODULE_TERMINE, STREAK_7, STREAK_30, XP_500, XP_1000, CERTIFIE, ENTRAIDE';
