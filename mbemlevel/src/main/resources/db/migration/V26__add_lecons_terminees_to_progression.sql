-- V26__add_lecons_terminees_to_progression.sql
-- Ajoute la colonne lecons_terminees à la table progression pour persister les leçons validées par apprenant

ALTER TABLE progression ADD COLUMN IF NOT EXISTS lecons_terminees TEXT;
