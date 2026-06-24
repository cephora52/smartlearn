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
