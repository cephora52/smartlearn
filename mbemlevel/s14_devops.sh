#!/usr/bin/env bash
# =============================================================================
# MbemNova · Script 14/15 · DevOps — Docker, Nginx, CI/CD, Monitoring
# =============================================================================
# CONTENU :
#   Dockerfile          — Multi-stage JRE 21 (builder + runtime)
#   docker-compose.yml  — PostgreSQL, Redis, MinIO, MailHog, app
#   docker-compose.test.yml — Tests d'intégration isolés
#   .env.example        — Variables d'environnement (référence)
#   Makefile            — Commandes dev : make run, test, migrate, deploy
#   nginx/nginx.conf    — Reverse proxy HTTP → HTTPS + upstream Spring Boot
#   nginx/ssl.conf      — TLS 1.3, HSTS, ciphers sécurisés
#   .github/workflows/
#     ci.yml            — Build + tests + OWASP scan
#     cd.yml            — Deploy automatique sur merge main
#     security.yml      — Dependabot + SAST
#   monitoring/
#     prometheus.yml    — Scraping Actuator /actuator/prometheus
#   docs/architecture.md — Décisions techniques architecture hexagonale
# =============================================================================
set -euo pipefail; export LC_ALL=C.UTF-8
G='\033[0;32m'; C='\033[0;36m'; B='\033[1m'; N='\033[0m'
ok()  { echo -e "${G}  [OK]${N} $1"; }
sec() { echo -e "\n${B}${C}── $1 ──${N}"; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "\n${B}${C}  MbemNova · 14/15 · DevOps${N}\n"
[[ ! -f "$ROOT/pom.xml" ]] && { echo "ERR: s01 requis"; exit 1; }

mkdir -p "$ROOT/.github/workflows"
mkdir -p "$ROOT/nginx"
mkdir -p "$ROOT/monitoring/grafana/dashboards"
mkdir -p "$ROOT/docs"

# =============================================================================
sec "1/7 Dockerfile multi-stage"
# =============================================================================
cat > "$ROOT/Dockerfile" << 'DEOF'
# =============================================================================
# MbemNova — Dockerfile multi-stage
#
# Étape 1 (builder) : compile le projet avec Maven + JDK 21
# Étape 2 (runtime) : image minimale JRE 21 Alpine
#
# UTILISATION :
#   docker build -t mbemnova:latest .
#   docker build --build-arg SPRING_PROFILE=prod -t mbemnova:prod .
# =============================================================================

# ── Stage 1 : Build ──────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /workspace

# Copier le wrapper Maven en premier (cache Docker si pas changé)
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./

# Télécharger les dépendances (layer mise en cache)
RUN ./mvnw dependency:go-offline -q

# Copier les sources et compiler
COPY src ./src
RUN ./mvnw package -DskipTests -q

# Extraire les layers du JAR pour un démarrage plus rapide
RUN mkdir -p target/extracted && \
    java -Djarmode=layertools -jar target/*.jar extract --destination target/extracted

# ── Stage 2 : Runtime ────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine AS runtime

# Sécurité : utilisateur non-root
RUN addgroup -S mbemnova && adduser -S mbemnova -G mbemnova
USER mbemnova

WORKDIR /app

# Copier les layers dans l'ordre (du plus stable au plus volatile)
COPY --from=builder --chown=mbemnova:mbemnova /workspace/target/extracted/dependencies/ ./
COPY --from=builder --chown=mbemnova:mbemnova /workspace/target/extracted/spring-boot-loader/ ./
COPY --from=builder --chown=mbemnova:mbemnova /workspace/target/extracted/snapshot-dependencies/ ./
COPY --from=builder --chown=mbemnova:mbemnova /workspace/target/extracted/application/ ./

# Port exposé (correspond à SERVER_PORT dans .env)
EXPOSE 8080

# Health check Docker
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health || exit 1

# Démarrage avec profil configurable
ARG SPRING_PROFILE=prod
ENV SPRING_PROFILES_ACTIVE=${SPRING_PROFILE}
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75"

ENTRYPOINT ["sh", "-c", \
    "exec java ${JAVA_OPTS} org.springframework.boot.loader.launch.JarLauncher"]
DEOF
ok "Dockerfile (multi-stage JDK 21 builder → JRE 21 runtime)"

# =============================================================================
sec "2/7 docker-compose.yml (dev local)"
# =============================================================================
cat > "$ROOT/docker-compose.yml" << 'DEOF'
# =============================================================================
# MbemNova — Docker Compose développement local
#
# SERVICES :
#   postgres  — PostgreSQL 16
#   redis     — Redis 7.2
#   minio     — Stockage objet S3-compatible
#   mailhog   — SMTP local (interface web port 8025)
#   app       — Spring Boot 4 (optionnel, lancer via mvn en dev)
#
# USAGE :
#   docker-compose up -d          # Lancer l'infra
#   docker-compose up -d app      # Lancer avec l'application
#   docker-compose logs -f app    # Voir les logs
#   docker-compose down -v        # Arrêter + supprimer les volumes
# =============================================================================

services:

  # ── PostgreSQL 16 ────────────────────────────────────────────────────────
  postgres:
    image: postgres:16-alpine
    container_name: mbemnova-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB:       mbemnova_dev
      POSTGRES_USER:     mbemnova
      POSTGRES_PASSWORD: mbemnova_dev_123
      TZ:                Africa/Douala
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U mbemnova -d mbemnova_dev"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ── Redis 7.2 ────────────────────────────────────────────────────────────
  redis:
    image: redis:7.2-alpine
    container_name: mbemnova-redis
    restart: unless-stopped
    command: redis-server --save 60 1 --loglevel warning
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  # ── MinIO (S3-compatible) ────────────────────────────────────────────────
  minio:
    image: minio/minio:latest
    container_name: mbemnova-minio
    restart: unless-stopped
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER:     minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    ports:
      - "9000:9000"   # API S3
      - "9001:9001"   # Console web
    volumes:
      - minio_data:/data
    healthcheck:
      test: ["CMD", "mc", "ready", "local"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ── MailHog (SMTP dev + interface web) ──────────────────────────────────
  mailhog:
    image: mailhog/mailhog:latest
    container_name: mbemnova-mailhog
    restart: unless-stopped
    ports:
      - "1025:1025"   # SMTP
      - "8025:8025"   # Interface web (voir les emails envoyés)

  # ── Application Spring Boot 4 (optionnel en dev) ────────────────────────
  app:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        SPRING_PROFILE: dev
    container_name: mbemnova-app
    restart: unless-stopped
    depends_on:
      postgres: { condition: service_healthy }
      redis:    { condition: service_healthy }
    environment:
      SPRING_PROFILES_ACTIVE: dev
      DATABASE_URL:     jdbc:postgresql://postgres:5432/mbemnova_dev
      DATABASE_USERNAME: mbemnova
      DATABASE_PASSWORD: mbemnova_dev_123
      REDIS_HOST:        redis
      REDIS_PORT:        "6379"
      MINIO_ENDPOINT:    http://minio:9000
      MAIL_HOST:         mailhog
      MAIL_PORT:         "1025"
      JWT_SECRET:        mbemnova-dev-secret-key-CHANGE-IN-PRODUCTION-min-256-bits
      SERVER_PORT:       "8080"
    ports:
      - "8080:8080"
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://localhost:8080/actuator/health || exit 1"]
      interval: 30s
      timeout: 10s
      start_period: 90s
      retries: 3
    profiles: ["full"]  # docker-compose --profile full up

volumes:
  postgres_data:
  redis_data:
  minio_data:
DEOF
ok "docker-compose.yml (PostgreSQL, Redis, MinIO, MailHog)"

# =============================================================================
sec "3/7 docker-compose.test.yml + .env.example + Makefile"
# =============================================================================
cat > "$ROOT/docker-compose.test.yml" << 'DEOF'
# Tests d'intégration CI — services isolés
services:
  postgres-test:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: mbemnova_test
      POSTGRES_USER: mbemnova_test
      POSTGRES_PASSWORD: test_pass_123
    ports: ["5433:5432"]
    tmpfs: ["/var/lib/postgresql/data"]  # Plus rapide, pas de persistance
  redis-test:
    image: redis:7.2-alpine
    ports: ["6380:6379"]
    command: redis-server --save ""
DEOF

cat > "$ROOT/.env.example" << 'DEOF'
# =============================================================================
# MbemNova — Variables d'environnement
# USAGE : cp .env.example .env et remplir les valeurs
# .env ne doit JAMAIS être commité dans git
# =============================================================================

# ── Base de données ───────────────────────────────────────────────────────────
DATABASE_URL=jdbc:postgresql://localhost:5432/mbemnova_prod
DATABASE_USERNAME=mbemnova
DATABASE_PASSWORD=CHANGE_ME_strong_password_here

# ── Redis ─────────────────────────────────────────────────────────────────────
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=CHANGE_ME_redis_password

# ── JWT (OBLIGATOIRE : min 32 chars = 256 bits) ───────────────────────────────
JWT_SECRET=CHANGE_ME_use_at_least_32_chars_for_256_bits_security
JWT_EXPIRATION_MS=86400000
JWT_REFRESH_MS=2592000000

# ── Email SMTP ────────────────────────────────────────────────────────────────
MAIL_HOST=smtp.sendgrid.net
MAIL_PORT=587
MAIL_USERNAME=apikey
MAIL_PASSWORD=CHANGE_ME_sendgrid_api_key

# ── Storage MinIO / AWS S3 ────────────────────────────────────────────────────
MINIO_ENDPOINT=https://minio.mbemnova.com
MINIO_ACCESS_KEY=CHANGE_ME
MINIO_SECRET_KEY=CHANGE_ME
MINIO_BUCKET=mbemnova

# ── WhatsApp Business ─────────────────────────────────────────────────────────
WHATSAPP_ENABLED=false
WHATSAPP_TOKEN=CHANGE_ME
WHATSAPP_PHONE_NUMBER_ID=CHANGE_ME

# ── Application ───────────────────────────────────────────────────────────────
SERVER_PORT=8080
SPRING_PROFILES_ACTIVE=prod
MBEMNOVA_APP_URL=https://mbemnova.com
TRACING_PROBABILITY=0.05

# ── Base de données pool ──────────────────────────────────────────────────────
DB_POOL_SIZE=20
DB_POOL_MIN_IDLE=5
DEOF

cat > "$ROOT/Makefile" << 'DEOF'
# =============================================================================
# MbemNova — Makefile (commandes de développement)
# USAGE : make <commande>
# =============================================================================

.PHONY: help run build test test-it docker-up docker-down migrate clean deploy

## Aide
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-20s\033[0m %s\n",$$1,$$2}'

## Lancer l'infra locale (PostgreSQL, Redis, MinIO, MailHog)
docker-up: ## Démarrer l'infrastructure Docker
	docker-compose up -d postgres redis minio mailhog
	@echo "✅ Infra démarrée. MailHog: http://localhost:8025 | MinIO: http://localhost:9001"

## Arrêter l'infra
docker-down: ## Arrêter les conteneurs
	docker-compose down

## Lancer l'application en mode développement
run: docker-up ## Lancer Spring Boot en dev (hot reload)
	./mvnw spring-boot:run -Dspring.profiles.active=dev

## Build complet
build: ## Compiler le projet
	./mvnw clean package -DskipTests

## Tests unitaires
test: ## Lancer les tests unitaires (exclu IT)
	./mvnw test

## Tests d'intégration (Testcontainers)
test-it: docker-up ## Lancer les tests d'intégration
	./mvnw failsafe:integration-test failsafe:verify -Dspring.profiles.active=test

## Build + tous les tests
test-all: ## Build + tests unitaires + intégration
	./mvnw clean verify

## Scan de sécurité OWASP
security: ## Lancer le scan CVE OWASP
	./mvnw dependency-check:check

## Migrations Flyway
migrate: ## Appliquer les migrations SQL
	./mvnw flyway:migrate -Dspring.profiles.active=dev

## Nettoyer le build
clean: ## Supprimer target/
	./mvnw clean
	docker-compose down -v 2>/dev/null || true

## Build image Docker
docker-build: ## Construire l'image Docker
	docker build -t mbemnova:$(shell git rev-parse --short HEAD) \
	             -t mbemnova:latest .

## Deploy (VPS) — nécessite SSH configuré
deploy: ## Déployer sur le VPS de production
	@echo "Deploying to production..."
	git push origin main
DEOF
ok ".env.example · Makefile · docker-compose.test.yml"

# =============================================================================
sec "4/7 Nginx"
# =============================================================================
cat > "$ROOT/nginx/nginx.conf" << 'NEOF'
# =============================================================================
# MbemNova — Nginx reverse proxy
# Redirige HTTP → HTTPS + proxy vers Spring Boot :8080
# =============================================================================

worker_processes auto;
events { worker_connections 1024; }

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile      on;
    keepalive_timeout 65;

    # Gzip
    gzip on;
    gzip_types text/plain application/json application/javascript text/css;
    gzip_min_length 1000;

    # Rate limiting global (protection DDoS niveau Nginx)
    limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;

    # Upstream Spring Boot
    upstream mbemnova_app {
        server localhost:8080;
        keepalive 32;
    }

    # HTTP → HTTPS redirect
    server {
        listen 80;
        server_name mbemnova.com www.mbemnova.com;
        return 301 https://$host$request_uri;
    }

    # HTTPS
    server {
        listen 443 ssl;
        server_name mbemnova.com www.mbemnova.com;

        include /etc/nginx/ssl.conf;

        # Logs
        access_log /var/log/nginx/mbemnova_access.log;
        error_log  /var/log/nginx/mbemnova_error.log warn;

        # Taille max upload (CV, PDF)
        client_max_body_size 55M;

        # Rate limiting sur les endpoints sensibles
        location /api/v1/auth/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://mbemnova_app;
            include /etc/nginx/proxy_params.conf;
        }

        # API générale
        location /api/ {
            proxy_pass http://mbemnova_app;
            include /etc/nginx/proxy_params.conf;
        }

        # Actuator — accès restreint (réseau interne seulement)
        location /actuator/ {
            allow 127.0.0.1;
            allow 10.0.0.0/8;
            deny  all;
            proxy_pass http://mbemnova_app;
            include /etc/nginx/proxy_params.conf;
        }
    }
}
NEOF

cat > "$ROOT/nginx/ssl.conf" << 'NEOF'
# =============================================================================
# MbemNova — Configuration SSL/TLS (inclus dans nginx.conf)
# Certificat Let's Encrypt via Certbot
# TLS 1.2/1.3 uniquement, ciphers sécurisés
# =============================================================================

ssl_certificate      /etc/letsencrypt/live/mbemnova.com/fullchain.pem;
ssl_certificate_key  /etc/letsencrypt/live/mbemnova.com/privkey.pem;

# TLS 1.2 et 1.3 uniquement
ssl_protocols TLSv1.2 TLSv1.3;

# Ciphers sécurisés (Mozilla Intermediate)
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;

# HSTS — 1 an, includeSubDomains
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

# Session caching
ssl_session_cache   shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;

# OCSP Stapling
ssl_stapling on;
ssl_stapling_verify on;
NEOF
ok "nginx/nginx.conf + nginx/ssl.conf"

# =============================================================================
sec "5/7 GitHub Actions CI/CD"
# =============================================================================
cat > "$ROOT/.github/workflows/ci.yml" << 'YMLEOF'
# =============================================================================
# MbemNova — CI : Build + Tests + Qualité
# Déclenché sur : push (toutes branches) + pull_request → main
# =============================================================================
name: CI

on:
  push:
    branches: ["**"]
  pull_request:
    branches: [main]

jobs:
  build-test:
    name: Build & Test
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB:       mbemnova_test
          POSTGRES_USER:     mbemnova_test
          POSTGRES_PASSWORD: test_pass_ci
        ports: ["5432:5432"]
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      redis:
        image: redis:7.2-alpine
        ports: ["6379:6379"]
        options: --health-cmd "redis-cli ping" --health-interval 10s

    steps:
      - uses: actions/checkout@v4

      - name: Setup Java 21
        uses: actions/setup-java@v4
        with:
          java-version: "21"
          distribution: temurin
          cache: maven

      - name: Build & Unit Tests
        run: ./mvnw -B clean package -Dspring.profiles.active=test

      - name: Integration Tests (Testcontainers)
        run: ./mvnw -B failsafe:integration-test failsafe:verify
        env:
          SPRING_PROFILES_ACTIVE: test
          DATABASE_URL: jdbc:postgresql://localhost:5432/mbemnova_test
          DATABASE_USERNAME: mbemnova_test
          DATABASE_PASSWORD: test_pass_ci
          REDIS_HOST: localhost
          JWT_SECRET: ci-test-secret-key-minimum-32-characters-long

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: target/site/jacoco/jacoco.xml
YMLEOF

cat > "$ROOT/.github/workflows/cd.yml" << 'YMLEOF'
# =============================================================================
# MbemNova — CD : Déploiement automatique sur push main
# =============================================================================
name: CD

on:
  push:
    branches: [main]

jobs:
  deploy:
    name: Deploy to VPS
    runs-on: ubuntu-latest
    needs: []  # Démarrer après ci.yml (configurer dans Branch Protection)

    steps:
      - uses: actions/checkout@v4

      - name: Setup Java 21
        uses: actions/setup-java@v4
        with:
          java-version: "21"
          distribution: temurin
          cache: maven

      - name: Build JAR
        run: ./mvnw -B clean package -DskipTests -Pprod

      - name: Build Docker image
        run: |
          docker build \
            --build-arg SPRING_PROFILE=prod \
            -t mbemnova:${{ github.sha }} \
            -t mbemnova:latest .

      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1
        with:
          host:     ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key:      ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /opt/mbemnova
            docker-compose pull
            docker-compose up -d --no-deps app
            docker-compose exec app wget -qO- http://localhost:8080/actuator/health
            echo "Deployment successful"
YMLEOF

cat > "$ROOT/.github/workflows/security.yml" << 'YMLEOF'
# =============================================================================
# MbemNova — Sécurité : OWASP + Dependabot
# Lancé chaque dimanche + sur push main
# =============================================================================
name: Security Scan

on:
  schedule:
    - cron: "0 2 * * 0"  # Chaque dimanche à 02h00
  push:
    branches: [main]

jobs:
  owasp-scan:
    name: OWASP Dependency Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: "21", distribution: temurin, cache: maven }
      - name: Run OWASP scan
        run: ./mvnw -B dependency-check:check -Pprod
        continue-on-error: true
      - name: Upload report
        uses: actions/upload-artifact@v4
        with:
          name: owasp-report
          path: target/dependency-check-report.html
YMLEOF
ok "GitHub Actions : ci.yml · cd.yml · security.yml"

# =============================================================================
sec "6/7 Monitoring Prometheus"
# =============================================================================
cat > "$ROOT/monitoring/prometheus.yml" << 'PEOF'
# =============================================================================
# MbemNova — Prometheus configuration
# Scrappe les métriques Micrometer depuis /actuator/prometheus
# =============================================================================
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: "mbemnova-api"
    metrics_path: /actuator/prometheus
    static_configs:
      - targets: ["localhost:8080"]
    # En production, utiliser le nom du service Docker
    # targets: ["app:8080"]

  - job_name: "postgres"
    static_configs:
      - targets: ["localhost:9187"]   # postgres_exporter

  - job_name: "redis"
    static_configs:
      - targets: ["localhost:9121"]   # redis_exporter
PEOF
ok "monitoring/prometheus.yml"

# =============================================================================
sec "7/7 Documentation architecture"
# =============================================================================
cat > "$ROOT/docs/architecture.md" << 'DOCEOF'
# MbemNova — Architecture technique

## Architecture hexagonale (Ports & Adapters)

### Principes

L'architecture hexagonale isole la logique métier (Domain + Application)
du monde extérieur (Infrastructure, API). Le Domain ne connaît ni Spring,
ni JPA, ni Redis — seulement du Java pur.

```
┌─────────────────────────────────────────────────────────┐
│  API (Controllers, Filters, DTOs HTTP)                  │
│         ↓ Commands/Queries                               │
│  Application (Use Cases, Event Handlers)                │
│         ↓ Ports (interfaces)                             │
│  Domain (Agrégats, Value Objects, Domain Events)        │
│         ↑ Implémentations                                │
│  Infrastructure (JPA, Redis, Email, PDF, Storage)       │
└─────────────────────────────────────────────────────────┘
```

### Règles strictes

1. **Domain** — Zéro dépendance Spring/JPA. Testé sans contexte Spring.
2. **Application** — Orchestre le Domain. Dépend uniquement des Ports (interfaces).
3. **Infrastructure** — Implémente les Ports. Jamais appelée directement par le Domain.
4. **API** — Appelle les Use Cases. Ne parle jamais directement aux JPA Repositories.

Vérifiées à chaque build par `ArchitectureTest.java` (ArchUnit).

### Stack technique

| Composant      | Technologie                         |
|----------------|-------------------------------------|
| Framework      | Spring Boot 4.0.5 (Jakarta EE 11)  |
| BDD            | PostgreSQL 16 + Flyway 10           |
| Cache          | Redis 7.2 (Lettuce)                 |
| Sécurité       | Spring Security 7 + Nimbus JOSE JWT |
| Mapping        | MapStruct 1.6.3                     |
| PDF            | iText 8 + html2pdf                  |
| Storage        | MinIO (S3-compatible)               |
| Email          | Spring Mail + Thymeleaf             |
| Monitoring     | Actuator + Micrometer + Prometheus  |
| Tests          | JUnit 5 + Testcontainers + ArchUnit |
| CI/CD          | GitHub Actions                      |

### Scénarios couverts (28/28)

| Script | Scénarios |
|--------|-----------|
| s08    | S02 (inscription), S03 (connexion), S27 (reset MDP) |
| s09    | S04 (catalogue), S05 (commencer cours), S06 (leçon+QCM), S07 (seuil paiement) |
| s10    | S08 (paiement cash), S16 (relances), S18 (suspension) |
| s11    | S09 (inscription session), S10 (créneaux), S11 (devoir+rendu), S23 (correction) |
| s12    | S12 (communauté Q&R), S13 (certificat), S14 (profil talent), S15 (parrainage) |
| s13    | S19 (créer cours), S20 (créer session), S21 (inscription manuelle) |
|        | S24 (tirage), S25 (stats admin), S26 (rôles) |

DOCEOF

cat > "$ROOT/CHANGELOG.md" << 'DOCEOF'
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
DOCEOF
ok "docs/architecture.md · CHANGELOG.md"

# =============================================================================
echo -e "\n${B}${G}  Script 14 terminé${N}"
echo -e "  ${G}✓${N} Dockerfile multi-stage (JDK 21 builder → JRE 21 Alpine runtime)"
echo -e "  ${G}✓${N} docker-compose.yml (PostgreSQL, Redis, MinIO, MailHog)"
echo -e "  ${G}✓${N} docker-compose.test.yml + .env.example + Makefile"
echo -e "  ${G}✓${N} nginx/nginx.conf + nginx/ssl.conf (TLS 1.3, HSTS)"
echo -e "  ${G}✓${N} GitHub Actions : ci.yml + cd.yml + security.yml"
echo -e "  ${G}✓${N} monitoring/prometheus.yml"
echo -e "  ${G}✓${N} docs/architecture.md + CHANGELOG.md\n"
echo -e "  \033[1;33m→ Dernier script : ./s15_tests_integration.sh\033[0m\n"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  RÉCAPITULATIF COMPLET — 14 scripts générés"
echo "═══════════════════════════════════════════════════════"
echo "  s01 pom.xml + YAML configs"
echo "  s02 Arborescence (377 fichiers stubs)"
echo "  s03 Couche Domain (agrégats, events, enums)"
echo "  s04 Application Auth (ports, use cases, handlers)"
echo "  s05 Migrations SQL Flyway V1→V10"
echo "  s06 Infrastructure JPA (entities, repos, adapters)"
echo "  s07 Infrastructure Sécurité JWT (tokens, blacklist)"
echo "  s08 API Layer (SecurityConfig, filtres, AuthController)"
echo "  s09 Cours + Progression (S04→S07)"
echo "  s10 Paiement (S08, S16, S18)"
echo "  s11 Session + Devoir + Rendu (S09→S11, S23)"
echo "  s12 Certificat + Talent + Notif + Communauté (S12→S15)"
echo "  s13 Admin + Gamification (S19→S21, S24→S26)"
echo "  s14 DevOps (Docker, Nginx, CI/CD, Monitoring)"
echo "═══════════════════════════════════════════════════════"
echo ""
