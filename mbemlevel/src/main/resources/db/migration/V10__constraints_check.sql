-- =============================================================================
-- MbemNova V10 — Contraintes CHECK métier supplémentaires
-- Ajoutées séparément pour une meilleure lisibilité et facilité de rollback.
-- =============================================================================

-- Un formateur ne peut pas s'inscrire à sa propre session
ALTER TABLE session_inscriptions
    ADD CONSTRAINT chk_session_inscription_pas_formateur
    CHECK (
        apprenant_id != (
            SELECT formateur_id FROM sessions WHERE id = session_id
        )
    );

-- Une tranche ne peut pas avoir une date de règlement avant sa création
ALTER TABLE tranches
    ADD CONSTRAINT chk_tranche_reglement_logique
    CHECK (date_reglement IS NULL OR date_reglement >= date_echeance - INTERVAL '30 days');

-- Le montant payé ne peut pas dépasser le montant total
ALTER TABLE paiements
    ADD CONSTRAINT chk_paiement_montant_logique
    CHECK (montant_paye <= montant_total);

-- Un rendu ne peut pas être soumis avant la création du devoir
-- (géré applicativement — contrainte BDD de sécurité)
ALTER TABLE rendus
    ADD CONSTRAINT chk_rendu_date_logique
    CHECK (date_soumission >= (
        SELECT created_at FROM devoirs WHERE id = devoir_id
    ) - INTERVAL '1 minute');

-- La note d'un avis cours requiert que l'apprenant ait complété 30% minimum
-- (vérifié applicativement dans le use case — commentaire pour documentation)
COMMENT ON TABLE avis_cours IS
    'Règle: un apprenant doit avoir complété >= 30% du cours pour laisser un avis (vérifié en application)';

-- Résumé des contraintes applicatives importantes
COMMENT ON TABLE progression IS
    'Règle: seuil_paiement configuré dans cours.seuil_paiement — contrôle applicatif';
COMMENT ON TABLE paiements IS
    'Règle: une seule demande de moratoire active à la fois par paiement — contrôle applicatif';
