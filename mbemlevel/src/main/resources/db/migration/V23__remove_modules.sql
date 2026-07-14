-- V23__remove_modules.sql
-- 1. Add cours_id to lecons table (initially without constraint)
ALTER TABLE lecons ADD COLUMN cours_id UUID;
 
-- 2. Delete orphan modules and their lessons before populating
DELETE FROM lecons WHERE module_id IN (SELECT id FROM modules WHERE cours_id NOT IN (SELECT id FROM cours));
DELETE FROM modules WHERE cours_id NOT IN (SELECT id FROM cours);
 
-- 3. Populate cours_id from modules
UPDATE lecons l
SET cours_id = m.cours_id
FROM modules m
WHERE l.module_id = m.id;
 
-- 4. Delete orphan lessons with no course associated
DELETE FROM lecons WHERE cours_id IS NULL;
 
-- 5. Make cours_id NOT NULL
ALTER TABLE lecons ALTER COLUMN cours_id SET NOT NULL;
 
-- 6. Add foreign key constraint to cours
ALTER TABLE lecons ADD CONSTRAINT lecons_cours_id_fkey FOREIGN KEY (cours_id) REFERENCES cours(id) ON DELETE CASCADE;
 
-- 7. Drop module_id constraint and column on lecons
ALTER TABLE lecons DROP COLUMN module_id;
 
-- 8. Drop module_id foreign key constraint and column on devoirs
ALTER TABLE devoirs DROP CONSTRAINT IF EXISTS devoirs_module_id_fkey;
ALTER TABLE devoirs DROP COLUMN IF EXISTS module_id;
 
-- 9. Drop modules table
DROP TABLE modules;
