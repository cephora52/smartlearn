-- MbemNova V25 — Mise à jour contrainte statut moratoires (S17)

-- Supprimer la contrainte existante sur le statut
ALTER TABLE moratoires DROP CONSTRAINT IF EXISTS moratoires_statut_check;

-- Mettre à jour les enregistrements existants d'ACCORDE vers APPROUVE
UPDATE moratoires SET statut = 'APPROUVE' WHERE statut = 'ACCORDE';

-- Ajouter la nouvelle contrainte sur le statut
ALTER TABLE moratoires ADD CONSTRAINT moratoires_statut_check CHECK (statut IN ('EN_ATTENTE', 'APPROUVE', 'REFUSE'));
