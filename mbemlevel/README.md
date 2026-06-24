# MbemNova — Plateforme EdTech Afrique Centrale

Formation tech de qualité · Douala, Cameroun 🇨🇲

## Démarrage rapide

### Prérequis
- Java 21 · Maven 3.9+ · Docker 24+

### Lancer en développement

```bash
# 1. Cloner le projet
git clone https://github.com/mbemnova/mbemlevel.git && cd mbemlevel

# 2. Copier et configurer les variables d'environnement
cp .env.example .env
# Éditer .env si nécessaire (les valeurs dev fonctionnent par défaut)

# 3. Démarrer l'infrastructure Docker (PostgreSQL, Redis, MinIO, MailHog)
make docker-up
# ou : docker-compose up -d postgres redis minio mailhog

# 4. Lancer Spring Boot
./mvnw spring-boot:run -Dspring.profiles.active=dev

# 5. Accéder à l'API
# → Swagger UI    : http://localhost:8080/swagger-ui.html
# → MailHog       : http://localhost:8025  (emails de dev)
# → MinIO Console : http://localhost:9001  (stockage fichiers)
```

### Commandes Makefile

| Commande         | Description                                |
|------------------|--------------------------------------------|
| `make docker-up` | Démarrer PostgreSQL, Redis, MinIO, MailHog |
| `make run`       | Lancer Spring Boot (dev)                   |
| `make test`      | Tests unitaires                            |
| `make test-it`   | Tests d'intégration (Testcontainers)       |
| `make test-all`  | Tous les tests + couverture JaCoCo         |
| `make build`     | Compiler le projet                         |
| `make security`  | Scan CVE OWASP                             |
| `make clean`     | Nettoyer le build                          |

### Structure du projet

```
src/main/java/com/mbem/mbemlevel/
├── domain/          # Agrégats, Value Objects, Domain Events — zéro Spring
├── application/     # Use Cases, Ports (interfaces), DTOs commands
├── infrastructure/  # JPA, Redis, Email, PDF, Storage
└── api/             # Controllers, Filtres, DTOs HTTP, Sécurité
```

Architecture hexagonale validée par ArchUnit à chaque build.

### Tests

```bash
# Unitaires (rapides, zéro Spring)
./mvnw test -Dtest="*Test"

# Intégration (Testcontainers — nécessite Docker)
./mvnw failsafe:integration-test -Dspring.profiles.active=test

# Tous + couverture
./mvnw clean verify
# → Rapport JaCoCo : target/site/jacoco/index.html
```

### Variables d'environnement clés

| Variable              | Description                        | Requis en prod |
|-----------------------|------------------------------------|----------------|
| `DATABASE_URL`        | URL PostgreSQL                     | ✅             |
| `JWT_SECRET`          | Secret JWT min 32 chars            | ✅             |
| `REDIS_HOST`          | Host Redis                         | ✅             |
| `MAIL_HOST`           | Host SMTP                          | ✅             |
| `MINIO_ENDPOINT`      | URL MinIO/S3                       | ✅             |
| `WHATSAPP_TOKEN`      | Token WhatsApp Business API        | ⚙️ Phase 2     |

Voir `.env.example` pour la liste complète.

## Scripts de génération

Le projet a été généré par 15 scripts shell :

```
s01 pom.xml + configs YAML     s09  Cours + Progression
s02 Arborescence (377 stubs)   s10  Paiement + Schedulers
s03 Couche Domain              s11  Session + Devoir + Rendu
s04 Application Auth           s12  Certificat + Talent + Communauté
s05 Migrations SQL Flyway      s13  Admin + Gamification
s06 Infrastructure JPA         s14  DevOps (Docker, Nginx, CI/CD)
s07 Sécurité JWT               s15  Tests + Documentation
s08 API Layer (Auth, Security)
```
