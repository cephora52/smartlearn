-- V29__add_final_quiz_done_to_progression.sql
-- Ajoute la colonne final_quiz_done à la table progression pour persister l'attribution unique des XP du quiz final

ALTER TABLE progression ADD COLUMN IF NOT EXISTS final_quiz_done BOOLEAN DEFAULT FALSE;
