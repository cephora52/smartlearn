# MbemNova — Guide de déploiement VPS

## Prérequis serveur

- Ubuntu 24.04 LTS · 2 vCPU · 4 GB RAM · 50 GB SSD
- Docker 24+ · Docker Compose v2
- Nginx · Certbot (Let's Encrypt)

## Déploiement initial

```bash
# 1. Cloner le projet
git clone https://github.com/mbemnova/mbemlevel.git /opt/mbemnova
cd /opt/mbemnova

# 2. Configurer les variables d'environnement
cp .env.example .env
nano .env  # Remplir TOUTES les valeurs (JWT_SECRET, DATABASE_PASSWORD, etc.)

# 3. Démarrer l'infrastructure
docker-compose up -d postgres redis minio

# 4. Attendre que PostgreSQL soit prêt
docker-compose exec postgres pg_isready -U mbemnova

# 5. Build et démarrer l'application
docker-compose up -d app

# 6. Vérifier la santé
curl http://localhost:8080/actuator/health
```

## Nginx + Let's Encrypt

```bash
# Installer Nginx et Certbot
apt install -y nginx certbot python3-certbot-nginx

# Copier la configuration
cp /opt/mbemnova/nginx/nginx.conf /etc/nginx/nginx.conf
cp /opt/mbemnova/nginx/ssl.conf   /etc/nginx/ssl.conf

# Obtenir le certificat SSL
certbot --nginx -d mbemnova.com -d www.mbemnova.com

# Tester et recharger Nginx
nginx -t && systemctl reload nginx
```

## Variables d'environnement obligatoires en production

```bash
DATABASE_URL=jdbc:postgresql://localhost:5432/mbemnova_prod
DATABASE_USERNAME=mbemnova
DATABASE_PASSWORD=<mot_de_passe_fort>
JWT_SECRET=<min_32_chars_aléatoires>
REDIS_HOST=localhost
REDIS_PASSWORD=<mot_de_passe_fort>
MAIL_HOST=smtp.sendgrid.net
MAIL_USERNAME=apikey
MAIL_PASSWORD=<sendgrid_api_key>
MINIO_ENDPOINT=https://minio.mbemnova.com
MINIO_ACCESS_KEY=<access_key>
MINIO_SECRET_KEY=<secret_key>
SPRING_PROFILES_ACTIVE=prod
```

## Mise à jour (zéro downtime)

```bash
cd /opt/mbemnova
git pull origin main
docker-compose build app
docker-compose up -d --no-deps app
# L'ancien container continue de servir pendant le démarrage du nouveau
```

## Surveillance

```bash
# Logs temps réel
docker-compose logs -f app

# Santé de l'application
curl http://localhost:8080/actuator/health

# Métriques Prometheus
curl http://localhost:8080/actuator/prometheus

# Statistiques Docker
docker stats mbemnova-app
```

## Backup PostgreSQL

```bash
# Backup quotidien (ajouter dans crontab)
pg_dump -U mbemnova mbemnova_prod | gzip > /backup/mbemnova_$(date +%Y%m%d).sql.gz

# Restauration
gunzip -c /backup/mbemnova_20250101.sql.gz | psql -U mbemnova mbemnova_prod
```
