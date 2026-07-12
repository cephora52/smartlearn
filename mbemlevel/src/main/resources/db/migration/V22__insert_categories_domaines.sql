-- Insertion des 6 domaines statiques requis
DELETE FROM categories;

INSERT INTO categories (id, nom, description, icone, created_at, updated_at) VALUES
('11111111-1111-1111-1111-111111111111', 'Bureautique & Productivité', 'Formations en pack office, dactylographie et outils de productivité.', 'laptop', NOW(), NOW()),
('22222222-2222-2222-2222-222222222222', 'Data et IA', 'Machine learning, python pour la data, visualisations et IA générative.', 'brain', NOW(), NOW()),
('33333333-3333-3333-3333-333333333333', 'Design Graphique et UI/UX', 'Design d interface, identités visuelles et outils de création graphique.', 'palette', NOW(), NOW()),
('44444444-4444-4444-4444-444444444444', 'Développement Web et Mobile', 'Apprenez le développement web full stack, mobile hybride et natif.', 'code', NOW(), NOW()),
('55555555-5555-5555-5555-555555555555', 'Marketing et Communication', 'Gestion de réseaux sociaux, marketing digital, publicité et branding.', 'megaphone', NOW(), NOW()),
('66666666-6666-6666-6666-666666666666', 'Réseaux Système et Sécurité', 'Administration réseau, systèmes d information et cybersécurité.', 'shield', NOW(), NOW());

-- Assigner les cours orphelins existants au domaine "Développement Web et Mobile" par défaut
UPDATE cours SET categorie_id = '44444444-4444-4444-4444-444444444444' WHERE categorie_id IS NULL;
