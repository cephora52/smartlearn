# Changelog MbemNova

## [1.0.0] — 2025-Q1 (MVP)

### Fonctionnalités
- Authentification JWT avec refresh tokens et blacklist Redis
- Catalogue de cours avec filtres et pagination
- Progression par leçons + QCM avec système XP et streak
- Seuil de conversion configurable par cours (30% défaut)
- Paiement cash avec plan de tranches et activation d'accès
- Sessions de formation avec créneaux hebdomadaires
- Devoirs + rendus + correction par le formateur
- Certificats PDF vérifiables publiquement
- Profil Talent (vitrine recruteurs)
- Communauté Q&R par cours
- Système de parrainage avec récompenses
- Tirage au sort mensuel automatique
- Back-office admin complet
- Notifications in-app + email (15 templates)
- Rate limiting (Bucket4j) + audit log immuable

### Architecture
- Architecture hexagonale (Ports & Adapters)
- Tests d'architecture ArchUnit (4 règles)
- 28 scénarios fonctionnels couverts
