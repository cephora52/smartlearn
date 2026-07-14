-- V24__add_nb_lecons_to_cours.sql
-- 1. Add nb_lecons column to cours table
ALTER TABLE cours ADD COLUMN IF NOT EXISTS nb_lecons INTEGER NOT NULL DEFAULT 0;

-- 2. Populate nb_lecons from existing lecons
UPDATE cours c
SET nb_lecons = (
    SELECT COALESCE(COUNT(*), 0)
    FROM lecons l
    WHERE l.cours_id = c.id
);
