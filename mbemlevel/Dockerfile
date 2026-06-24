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
