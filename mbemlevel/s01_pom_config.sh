#!/usr/bin/env bash
# =============================================================================
# MbemNova — Script 01/15 : pom.xml + Configurations YAML
# =============================================================================
# RÔLE   : Génère le pom.xml Spring Boot 4 et les 4 fichiers YAML
#          (base + dev + test + prod) + logback-spring.xml
#
# PRÉREQUIS : Être à la racine du projet (là où est le pom.xml existant)
#
# USAGE  :
#   chmod +x s01_pom_config.sh
#   ./s01_pom_config.sh
#
# IMPORTANT : Ce script REMPLACE le pom.xml minimal créé par Spring Initializr
#             et REMPLACE application.yaml — les vôtres seront sauvegardés
#             sous pom.xml.bak et application.yaml.bak
# =============================================================================

set -euo pipefail
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# ── Couleurs terminal ─────────────────────────────────────────────────────────
C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_YELLOW='\033[1;33m'
C_RED='\033[0;31m';   C_CYAN='\033[0;36m'; C_BOLD='\033[1m'; C_NC='\033[0m'

log_ok()  { echo -e "${C_GREEN}  [OK]${C_NC} $1"; }
log_inf() { echo -e "${C_BLUE}  [..]${C_NC} $1"; }
log_sec() { echo -e "\n${C_BOLD}${C_CYAN}── $1 ──${C_NC}"; }
log_err() { echo -e "${C_RED}  [!!]${C_NC} $1" >&2; }

# ── Vérification ──────────────────────────────────────────────────────────────
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RES="$ROOT/src/main/resources"

echo ""
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo -e "${C_BOLD}${C_CYAN}  MbemNova · Script 01/15 · pom.xml + YAML     ${C_NC}"
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo ""
log_inf "Racine projet : $ROOT"

[[ ! -f "$ROOT/pom.xml" ]] && { log_err "pom.xml introuvable — lancez depuis la racine du projet"; exit 1; }

# Sauvegarder les fichiers existants
[[ -f "$ROOT/pom.xml" ]]      && cp "$ROOT/pom.xml"      "$ROOT/pom.xml.bak"
[[ -f "$RES/application.yaml" ]] && cp "$RES/application.yaml" "$RES/application.yaml.bak"
log_inf "Sauvegardes : pom.xml.bak + application.yaml.bak"
mkdir -p "$RES"

# =============================================================================
# FICHIER 1 — pom.xml
# Spring Boot 4.0.5 · Java 21 · Jakarta EE 11
# Règles strictes :
#   - Versions explicites pour tout ce qui n'est pas dans le BOM Spring Boot 4
#   - flyway-database-postgresql OBLIGATOIRE (Flyway 10+)
#   - Lombok AVANT MapStruct dans annotationProcessorPaths
#   - --enable-preview retiré (risque de problèmes en CI)
#   - Un seul web stack : spring-boot-starter-web (MVC, pas WebFlux)
# =============================================================================
log_sec "1/6 pom.xml"

cat > "$ROOT/pom.xml" << 'POMEOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <!-- ═══════════════════════════════════════════════════════════════
       PARENT Spring Boot 4.0.5
       Gère automatiquement les versions de toutes les dépendances
       Spring. Ne JAMAIS surcharger une version gérée par ce BOM
       sans raison impérative.
       ═══════════════════════════════════════════════════════════════ -->
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.0.5</version>
    <relativePath/>
  </parent>

  <!-- ═══════════════════════════════════════════════════════════════
       IDENTITÉ
       ═══════════════════════════════════════════════════════════════ -->
  <groupId>com.mbem</groupId>
  <artifactId>mbemlevel</artifactId>
  <version>1.0.0-SNAPSHOT</version>
  <packaging>jar</packaging>
  <name>MbemNova</name>
  <description>Plateforme EdTech — Formation tech Afrique Centrale</description>

  <!-- ═══════════════════════════════════════════════════════════════
       PROPRIÉTÉS — Toutes les versions non-BOM centralisées ici.
       Modifier une version : changer UNE ligne dans cette section.
       ═══════════════════════════════════════════════════════════════ -->
  <properties>
    <!-- Runtime -->
    <java.version>21</java.version>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>

    <!-- Versions hors BOM Spring Boot 4 (explicites obligatoires) -->
    <mapstruct.version>1.6.3</mapstruct.version>
    <lombok-mapstruct-binding.version>0.2.0</lombok-mapstruct-binding.version>
    <bucket4j.version>8.14.0</bucket4j.version>
    <resilience4j.version>2.3.0</resilience4j.version>
    <springdoc.version>2.8.9</springdoc.version>
    <itext.version>8.0.5</itext.version>
    <awssdk.version>2.29.50</awssdk.version>
    <archunit.version>1.3.0</archunit.version>
    <jasypt.version>3.0.5</jasypt.version>
    <commons-io.version>2.18.0</commons-io.version>

    <!-- Versions plugins Maven -->
    <maven-compiler-plugin.version>3.13.0</maven-compiler-plugin.version>
    <maven-surefire-plugin.version>3.5.2</maven-surefire-plugin.version>
    <maven-failsafe-plugin.version>3.5.2</maven-failsafe-plugin.version>
    <jacoco.version>0.8.12</jacoco.version>
    <owasp-dependency-check.version>11.1.1</owasp-dependency-check.version>
  </properties>

  <dependencies>

    <!-- ═══════════════════════════════════════════════════════════
         SPRING BOOT — Web MVC (REST)
         Utilise spring-boot-starter-web (MVC + Tomcat embarqué).
         NE PAS ajouter spring-webflux : incompatible dans le même
         contexte applicatif que spring-boot-starter-web.
         ═══════════════════════════════════════════════════════════ -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <!-- Validation Jakarta EE 11 (@NotBlank, @Email…) -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>

    <!-- AOP — @Aspect pour Audit, Performance, Sécurité -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-aop</artifactId>
    </dependency>

    <!-- Processor @ConfigurationProperties (génère metadata IDE) -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-configuration-processor</artifactId>
      <optional>true</optional>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         BASE DE DONNÉES
         ═══════════════════════════════════════════════════════════ -->

    <!-- Spring Data JPA + Hibernate 7 (jakarta.persistence.*) -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>

    <!-- Driver PostgreSQL -->
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <scope>runtime</scope>
    </dependency>

    <!-- Flyway Core — migrations versionnées -->
    <dependency>
      <groupId>org.flywaydb</groupId>
      <artifactId>flyway-core</artifactId>
    </dependency>

    <!--
      OBLIGATOIRE depuis Flyway 10 : module spécifique PostgreSQL.
      Sans cette dépendance, Flyway lève une erreur au démarrage :
      "No Flyway Community Edition extension found for postgresql"
    -->
    <dependency>
      <groupId>org.flywaydb</groupId>
      <artifactId>flyway-database-postgresql</artifactId>
      <scope>runtime</scope>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         CACHE — Redis (Lettuce client inclus dans le starter)
         ═══════════════════════════════════════════════════════════ -->

    <!-- Spring Data Redis -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-redis</artifactId>
    </dependency>

    <!-- Annotations @Cacheable @CacheEvict @CachePut -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-cache</artifactId>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         SÉCURITÉ — Spring Security 7 + JWT (Nimbus JOSE)
         ═══════════════════════════════════════════════════════════ -->

    <!-- Spring Security 7 -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-security</artifactId>
    </dependency>

    <!--
      OAuth2 Resource Server inclut nimbus-jose-jwt.
      Fournit JwtDecoder, JwtEncoder, BearerTokenAuthenticationFilter.
      Ne pas ajouter nimbus-jose-jwt séparément : doublon de version.
    -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         RATE LIMITING — Bucket4j (algorithme token bucket)
         ═══════════════════════════════════════════════════════════ -->

    <dependency>
      <groupId>com.bucket4j</groupId>
      <artifactId>bucket4j-core</artifactId>
      <version>${bucket4j.version}</version>
    </dependency>

    <!-- Stockage distribué des buckets dans Redis -->
    <dependency>
      <groupId>com.bucket4j</groupId>
      <artifactId>bucket4j-redis</artifactId>
      <version>${bucket4j.version}</version>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         RÉSILIENCE — Circuit Breaker, Retry (Resilience4j)
         ═══════════════════════════════════════════════════════════ -->

    <!--
      Utiliser spring-boot3 même pour Spring Boot 4 (API compatible).
      Le suffix -boot3 signifie "compatible Spring Boot 3/4 + Jakarta EE".
    -->
    <dependency>
      <groupId>io.github.resilience4j</groupId>
      <artifactId>resilience4j-spring-boot3</artifactId>
      <version>${resilience4j.version}</version>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         MONITORING — Actuator + Prometheus
         ═══════════════════════════════════════════════════════════ -->

    <!-- /actuator/health · /actuator/metrics · /actuator/prometheus -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>

    <!-- Export métriques Prometheus (scraping par Grafana) -->
    <dependency>
      <groupId>io.micrometer</groupId>
      <artifactId>micrometer-registry-prometheus</artifactId>
      <scope>runtime</scope>
    </dependency>

    <!-- Distributed tracing pour corréler les logs -->
    <dependency>
      <groupId>io.micrometer</groupId>
      <artifactId>micrometer-tracing-bridge-brave</artifactId>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         EMAIL + TEMPLATES HTML (Thymeleaf)
         ═══════════════════════════════════════════════════════════ -->

    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-mail</artifactId>
    </dependency>

    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-thymeleaf</artifactId>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         PDF — iText 8 (factures + certificats)
         ═══════════════════════════════════════════════════════════ -->

    <!-- BOM iText (importer les modules séparément) -->
    <dependency>
      <groupId>com.itextpdf</groupId>
      <artifactId>itext-core</artifactId>
      <version>${itext.version}</version>
      <type>pom</type>
    </dependency>

    <!-- Conversion HTML → PDF (templates Thymeleaf → PDF) -->
    <dependency>
      <groupId>com.itextpdf</groupId>
      <artifactId>html2pdf</artifactId>
      <version>${itext.version}</version>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         STOCKAGE OBJET — AWS SDK S3 v2 (compatible MinIO)
         ═══════════════════════════════════════════════════════════ -->

    <dependency>
      <groupId>software.amazon.awssdk</groupId>
      <artifactId>s3</artifactId>
      <version>${awssdk.version}</version>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         MAPPING — MapStruct + Lombok
         ORDRE CRITIQUE dans annotationProcessorPaths :
         Lombok → lombok-mapstruct-binding → MapStruct
         Inverser cet ordre = getters non trouvés à la compilation
         ═══════════════════════════════════════════════════════════ -->

    <dependency>
      <groupId>org.mapstruct</groupId>
      <artifactId>mapstruct</artifactId>
      <version>${mapstruct.version}</version>
    </dependency>

    <dependency>
      <groupId>org.projectlombok</groupId>
      <artifactId>lombok</artifactId>
      <optional>true</optional>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         DOCUMENTATION API — SpringDoc OpenAPI 3 (Swagger UI)
         ═══════════════════════════════════════════════════════════ -->

    <dependency>
      <groupId>org.springdoc</groupId>
      <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
      <version>${springdoc.version}</version>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         CHIFFREMENT — Jasypt (champs sensibles en BDD)
         ═══════════════════════════════════════════════════════════ -->

    <dependency>
      <groupId>com.github.ulisesbocchio</groupId>
      <artifactId>jasypt-spring-boot-starter</artifactId>
      <version>${jasypt.version}</version>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         UTILITAIRES
         ═══════════════════════════════════════════════════════════ -->

    <dependency>
      <groupId>org.apache.commons</groupId>
      <artifactId>commons-lang3</artifactId>
    </dependency>

    <dependency>
      <groupId>commons-io</groupId>
      <artifactId>commons-io</artifactId>
      <version>${commons-io.version}</version>
    </dependency>

    <!-- Module Jackson pour java.time.* (LocalDateTime → JSON ISO) -->
    <dependency>
      <groupId>com.fasterxml.jackson.datatype</groupId>
      <artifactId>jackson-datatype-jsr310</artifactId>
    </dependency>

    <!-- ═══════════════════════════════════════════════════════════
         TESTS
         ═══════════════════════════════════════════════════════════ -->

    <!-- Spring Boot Test (MockMvc, @SpringBootTest, Mockito) -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
    </dependency>

    <!-- @WithMockUser, SecurityMockMvcRequestPostProcessors -->
    <dependency>
      <groupId>org.springframework.security</groupId>
      <artifactId>spring-security-test</artifactId>
      <scope>test</scope>
    </dependency>

    <!-- Testcontainers — intégration Spring Boot (gère le lifecycle) -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-testcontainers</artifactId>
      <scope>test</scope>
    </dependency>

    <dependency>
      <groupId>org.testcontainers</groupId>
      <artifactId>junit-jupiter</artifactId>
      <scope>test</scope>
    </dependency>

    <!-- PostgreSQL réel en test d'intégration -->
    <dependency>
      <groupId>org.testcontainers</groupId>
      <artifactId>postgresql</artifactId>
      <scope>test</scope>
    </dependency>

    <!-- ArchUnit — validation architecture hexagonale à la compilation -->
    <dependency>
      <groupId>com.tngtech.archunit</groupId>
      <artifactId>archunit-junit5</artifactId>
      <version>${archunit.version}</version>
      <scope>test</scope>
    </dependency>

    <!-- H2 — base mémoire pour tests unitaires ultra-rapides -->
    <dependency>
      <groupId>com.h2database</groupId>
      <artifactId>h2</artifactId>
      <scope>test</scope>
    </dependency>

  </dependencies>

  <!-- ═══════════════════════════════════════════════════════════════
       BUILD — PLUGINS
       ═══════════════════════════════════════════════════════════════ -->
  <build>
    <plugins>

      <!-- Spring Boot Maven Plugin — JAR exécutable -->
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <configuration>
          <!-- Exclure Lombok du JAR final (compile-time uniquement) -->
          <excludes>
            <exclude>
              <groupId>org.projectlombok</groupId>
              <artifactId>lombok</artifactId>
            </exclude>
          </excludes>
        </configuration>
        <executions>
          <execution>
            <!-- Génère META-INF/build-info.properties (version, git commit) -->
            <goals><goal>build-info</goal></goals>
          </execution>
        </executions>
      </plugin>

      <!-- ───────────────────────────────────────────────────────
           Compilateur Java 21
           ORDRE annotationProcessorPaths CRITIQUE :
           1. Lombok  → génère getters/setters/constructeurs
           2. Binding → compatibilité Lombok + MapStruct
           3. MapStruct → utilise les getters Lombok
           4. SB Config → génère metadata @ConfigurationProperties
           ─────────────────────────────────────────────────────── -->
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>${maven-compiler-plugin.version}</version>
        <configuration>
          <source>21</source>
          <target>21</target>
          <encoding>UTF-8</encoding>
          <!-- Option MapStruct : toujours utiliser Spring comme componentModel -->
          <compilerArgs>
            <arg>-Amapstruct.defaultComponentModel=spring</arg>
            <arg>-Amapstruct.unmappedTargetPolicy=ERROR</arg>
          </compilerArgs>
          <annotationProcessorPaths>
            <!-- 1. Lombok en premier — obligatoire -->
            <path>
              <groupId>org.projectlombok</groupId>
              <artifactId>lombok</artifactId>
            </path>
            <!-- 2. Binding Lombok-MapStruct — assure la compatibilité -->
            <path>
              <groupId>org.projectlombok</groupId>
              <artifactId>lombok-mapstruct-binding</artifactId>
              <version>${lombok-mapstruct-binding.version}</version>
            </path>
            <!-- 3. MapStruct processor — après Lombok -->
            <path>
              <groupId>org.mapstruct</groupId>
              <artifactId>mapstruct-processor</artifactId>
              <version>${mapstruct.version}</version>
            </path>
            <!-- 4. Spring Boot Config Processor -->
            <path>
              <groupId>org.springframework.boot</groupId>
              <artifactId>spring-boot-configuration-processor</artifactId>
            </path>
          </annotationProcessorPaths>
        </configuration>
      </plugin>

      <!-- Tests unitaires (exclu les *IT.java) -->
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>${maven-surefire-plugin.version}</version>
        <configuration>
          <argLine>${argLine}</argLine>
          <excludes>
            <exclude>**/*IT.java</exclude>
            <exclude>**/*IntegrationTest.java</exclude>
          </excludes>
        </configuration>
      </plugin>

      <!-- Tests d'intégration (*IT.java — Testcontainers) -->
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-failsafe-plugin</artifactId>
        <version>${maven-failsafe-plugin.version}</version>
        <configuration>
          <argLine>${argLine}</argLine>
          <includes>
            <include>**/*IT.java</include>
            <include>**/*IntegrationTest.java</include>
          </includes>
        </configuration>
        <executions>
          <execution>
            <goals>
              <goal>integration-test</goal>
              <goal>verify</goal>
            </goals>
          </execution>
        </executions>
      </plugin>

      <!--
        JaCoCo — Couverture de code.
        Seuil minimum : 80% sur domain/ et application/usecase/
        (le cœur métier doit être bien testé).
      -->
      <plugin>
        <groupId>org.jacoco</groupId>
        <artifactId>jacoco-maven-plugin</artifactId>
        <version>${jacoco.version}</version>
        <executions>
          <execution>
            <goals><goal>prepare-agent</goal></goals>
          </execution>
          <execution>
            <id>jacoco-report</id>
            <phase>test</phase>
            <goals><goal>report</goal></goals>
          </execution>
          <execution>
            <id>jacoco-check</id>
            <goals><goal>check</goal></goals>
            <configuration>
              <rules>
                <rule>
                  <element>PACKAGE</element>
                  <limits>
                    <limit>
                      <counter>LINE</counter>
                      <value>COVEREDRATIO</value>
                      <minimum>0.80</minimum>
                    </limit>
                  </limits>
                  <includes>
                    <include>com/mbem/mbemlevel/domain/**</include>
                    <include>com/mbem/mbemlevel/application/usecase/**</include>
                  </includes>
                </rule>
              </rules>
            </configuration>
          </execution>
        </executions>
      </plugin>

      <!--
        OWASP Dependency Check — CVE scan.
        Lancer manuellement : mvn dependency-check:check
        Activé automatiquement dans le profil "prod".
      -->
      <plugin>
        <groupId>org.owasp</groupId>
        <artifactId>dependency-check-maven</artifactId>
        <version>${owasp-dependency-check.version}</version>
        <configuration>
          <failBuildOnCVSS>7</failBuildOnCVSS>
          <skipTestScope>true</skipTestScope>
          <formats>
            <format>HTML</format>
            <format>JSON</format>
          </formats>
        </configuration>
      </plugin>

    </plugins>
  </build>

  <!-- ═══════════════════════════════════════════════════════════════
       PROFILS MAVEN
       ═══════════════════════════════════════════════════════════════ -->
  <profiles>

    <!-- Développement local (actif par défaut) -->
    <profile>
      <id>dev</id>
      <activation><activeByDefault>true</activeByDefault></activation>
      <properties>
        <spring.profiles.active>dev</spring.profiles.active>
      </properties>
    </profile>

    <!-- CI/CD (tests automatisés) -->
    <profile>
      <id>ci</id>
      <properties>
        <spring.profiles.active>test</spring.profiles.active>
      </properties>
    </profile>

    <!-- Production — active l'OWASP check obligatoire -->
    <profile>
      <id>prod</id>
      <properties>
        <spring.profiles.active>prod</spring.profiles.active>
      </properties>
      <build>
        <plugins>
          <plugin>
            <groupId>org.owasp</groupId>
            <artifactId>dependency-check-maven</artifactId>
            <executions>
              <execution>
                <goals><goal>check</goal></goals>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
    </profile>

  </profiles>

</project>
POMEOF
log_ok "pom.xml — Spring Boot 4.0.5 complet"

# =============================================================================
# FICHIER 2 — application.yaml (configuration COMMUNE à tous les profils)
# Règle : ne mettre ici QUE ce qui est identique en dev, test ET prod.
# Tout ce qui varie par environnement va dans le fichier de profil.
# =============================================================================
log_sec "2/6 application.yaml (base commune)"

cat > "$RES/application.yaml" << 'YMLEOF'
# =============================================================================
# MbemNova — Configuration commune à tous les environnements
#
# RÈGLE STRICTE : Ce fichier ne contient QUE les valeurs identiques
# en dev, test et prod. Les valeurs spécifiques à un environnement
# sont dans application-{profil}.yaml.
#
# JAMAIS de secrets ici (mots de passe, clés API, JWT secret).
# =============================================================================

spring:
  application:
    name: mbemlevel

  # Activation du profil via variable d'environnement SPRING_PROFILES_ACTIVE
  # Valeur par défaut : dev (surchargée en CI par -Dspring.profiles.active=test)
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}

  # ── Sérialisation JSON ──────────────────────────────────────────────────────
  jackson:
    # Timezone Afrique Centrale (Cameroun = UTC+1)
    time-zone: Africa/Douala
    serialization:
      write-dates-as-timestamps: false   # Toujours ISO-8601 : "2025-01-01T08:00:00"
      fail-on-empty-beans: false
    deserialization:
      fail-on-unknown-properties: false  # Tolérant aux champs inconnus (évolutivité API)
    default-property-inclusion: NON_NULL # Pas de champs null dans les réponses JSON

  # ── JPA — Paramètres communs ─────────────────────────────────────────────────
  jpa:
    # CRITIQUE : désactiver open-in-view pour éviter les transactions long-running
    # et les problèmes de lazy loading hors transaction
    open-in-view: false
    properties:
      hibernate:
        # Batch inserts/updates : réduit les aller-retours BDD (perf x5 en bulk)
        jdbc:
          batch_size: 25
          order_inserts: true
          order_updates: true
        # Détecte les pagination sur collections (problème N+1 classique)
        query:
          fail_on_pagination_over_collection_fetch: true
        # Format UTC en BDD, conversion application selon la timezone configurée
        jdbc.time_zone: UTC

  # ── Flyway ───────────────────────────────────────────────────────────────────
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true           # Crée la baseline si la BDD existe déjà
    out-of-order: false                  # Migrations dans l'ordre strict
    validate-on-migrate: true            # Vérifie les checksums à chaque démarrage

  # ── Cache ────────────────────────────────────────────────────────────────────
  cache:
    type: redis

  # ── Upload de fichiers ───────────────────────────────────────────────────────
  servlet:
    multipart:
      enabled: true
      max-file-size: 50MB
      max-request-size: 55MB

  # ── Thymeleaf (templates emails) ─────────────────────────────────────────────
  thymeleaf:
    prefix: classpath:/templates/email/
    suffix: .html
    encoding: UTF-8

# ── Serveur HTTP ───────────────────────────────────────────────────────────────
server:
  port: ${SERVER_PORT:8080}
  compression:
    enabled: true
    mime-types: application/json,text/html,text/plain
    min-response-size: 1024
  http2:
    enabled: true
  # Ne JAMAIS exposer les détails d'erreur internes au client
  error:
    include-message: never
    include-stacktrace: never
    include-exception: false
    include-binding-errors: never

# ── Actuator ──────────────────────────────────────────────────────────────────
management:
  endpoints:
    web:
      base-path: /actuator
  endpoint:
    health:
      # Détails réservés aux utilisateurs authentifiés (ADMIN)
      show-details: when-authorized
  metrics:
    tags:
      # Ces tags apparaissent sur TOUTES les métriques Prometheus
      application: ${spring.application.name}

# ── SpringDoc / Swagger UI ────────────────────────────────────────────────────
springdoc:
  api-docs:
    path: /v3/api-docs
  swagger-ui:
    path: /swagger-ui.html
    operationsSorter: method
    tagsSorter: alpha
    try-it-out-enabled: true

# ── Configuration métier MbemNova ─────────────────────────────────────────────
mbemnova:
  cours:
    seuil-paiement-defaut: 0.30     # 30% du cours = seuil de conversion
    xp-par-lecon: 25
    xp-bonus-module: 100
    score-min-qcm: 70               # Score minimum pour valider un QCM (%)
  security:
    refresh-token-ttl-jours: 30
    reset-token-ttl-minutes: 60
    max-tentatives-connexion: 5
    blocage-connexion-minutes: 30
  gamification:
    tirage-jour: 1                  # 1er du mois (CRON)
    tirage-heure: 8                 # 08h00 Africa/Douala
YMLEOF
log_ok "application.yaml (base commune)"

# =============================================================================
# FICHIER 3 — application-dev.yaml (développement local)
# =============================================================================
log_sec "3/6 application-dev.yaml"

cat > "$RES/application-dev.yaml" << 'YMLEOF'
# =============================================================================
# MbemNova — Profil DEV (développement local)
# Activé par : SPRING_PROFILES_ACTIVE=dev (défaut)
#
# Ce fichier contient UNIQUEMENT les surcharges spécifiques au dev.
# Toutes les valeurs sensibles utilisent des défauts sécurisés localement.
# NE JAMAIS commiter de vraies credentials ici.
# =============================================================================

spring:
  # ── Base de données PostgreSQL locale ───────────────────────────────────────
  datasource:
    url: jdbc:postgresql://localhost:5432/mbemnova_dev
    username: ${DB_USERNAME:mbemnova}
    password: ${DB_PASSWORD:mbemnova_dev_123}
    driver-class-name: org.postgresql.Driver
    hikari:
      pool-name: HikariPool-Dev
      maximum-pool-size: 10
      minimum-idle: 2
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000

  # ── JPA — visible en dev pour debug ─────────────────────────────────────────
  jpa:
    hibernate:
      # Flyway gère le schéma — JAMAIS create/update/create-drop en prod
      ddl-auto: validate
    show-sql: true
    properties:
      hibernate:
        format_sql: true
        use_sql_comments: true

  # ── Redis local ──────────────────────────────────────────────────────────────
  data:
    redis:
      host: ${REDIS_HOST:localhost}
      port: ${REDIS_PORT:6379}
      password: ${REDIS_PASSWORD:}
      timeout: 2000ms
      lettuce:
        pool:
          max-active: 8
          min-idle: 0

  # ── Email — MailHog local (serveur SMTP de test) ─────────────────────────────
  mail:
    host: ${MAIL_HOST:localhost}
    port: ${MAIL_PORT:1025}
    username: ${MAIL_USERNAME:}
    password: ${MAIL_PASSWORD:}
    properties:
      mail.smtp.auth: false
      mail.smtp.starttls.enable: false

  # ── Thymeleaf — rechargement à chaud des templates ─────────────────────────
  thymeleaf:
    cache: false

  # ── DevTools ────────────────────────────────────────────────────────────────
  devtools:
    restart:
      enabled: true
    livereload:
      enabled: true

# ── Actuator — tout exposer en dev ────────────────────────────────────────────
management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: always
  tracing:
    sampling:
      probability: 1.0              # 100% des traces en dev

# ── Swagger activé en dev ────────────────────────────────────────────────────
springdoc:
  swagger-ui:
    enabled: true
  api-docs:
    enabled: true

# ── JWT — clé de dev (JAMAIS utiliser en prod) ───────────────────────────────
security:
  jwt:
    secret: ${JWT_SECRET:mbemnova-dev-only-secret-key-change-in-production-min-256-bits}
    expiration-ms: ${JWT_EXPIRATION_MS:86400000}          # 24h
    refresh-expiration-ms: ${JWT_REFRESH_MS:2592000000}   # 30j

# ── Logs — DEBUG en dev ───────────────────────────────────────────────────────
logging:
  level:
    root: INFO
    com.mbem.mbemlevel: DEBUG
    org.springframework.security: DEBUG
    org.hibernate.SQL: DEBUG
    org.hibernate.orm.jdbc.bind: TRACE
    org.flywaydb: DEBUG
  pattern:
    # Pattern lisible humain pour le terminal dev
    console: "%d{HH:mm:ss.SSS} %highlight(%-5level) [%cyan(%X{requestId:--})] %logger{36} — %msg%n"
YMLEOF
log_ok "application-dev.yaml"

# =============================================================================
# FICHIER 4 — application-test.yaml (CI/CD + tests d'intégration)
# =============================================================================
log_sec "4/6 application-test.yaml"

cat > "$RES/application-test.yaml" << 'YMLEOF'
# =============================================================================
# MbemNova — Profil TEST (Testcontainers + CI/CD)
# Activé par : SPRING_PROFILES_ACTIVE=test
#
# Testcontainers démarre automatiquement PostgreSQL dans Docker.
# L'URL JDBC tc:postgresql:// est interceptée par Testcontainers.
# Redis : en mémoire via EmbeddedRedis ou Testcontainers Redis.
# =============================================================================

spring:
  # ── PostgreSQL Testcontainers ────────────────────────────────────────────────
  datasource:
    # TC_REUSABLE=true : réutilise le container entre les tests (plus rapide)
    url: jdbc:tc:postgresql:16:///mbemnova_test?TC_REUSABLE=true
    driver-class-name: org.testcontainers.jdbc.ContainerDatabaseDriver
    hikari:
      pool-name: HikariPool-Test
      maximum-pool-size: 5
      minimum-idle: 1

  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false                   # Silencieux en CI

  # ── Flyway — autoriser clean uniquement en test ──────────────────────────────
  flyway:
    clean-disabled: false             # Permet @Sql(scripts = "cleanup.sql")

  # ── Email — désactivé en test ────────────────────────────────────────────────
  mail:
    host: localhost
    port: 25
    properties:
      mail.smtp.auth: false

  # ── Thymeleaf — cache en test ────────────────────────────────────────────────
  thymeleaf:
    cache: true

# ── Actuator — minimal en test ────────────────────────────────────────────────
management:
  endpoints:
    web:
      exposure:
        include: health,info
  tracing:
    sampling:
      probability: 0.0              # Pas de tracing en test

# ── Swagger désactivé en test ────────────────────────────────────────────────
springdoc:
  swagger-ui:
    enabled: false
  api-docs:
    enabled: false

# ── JWT test (clé fixe pour reproductibilité) ────────────────────────────────
security:
  jwt:
    secret: mbemnova-test-secret-key-fixed-for-reproducible-tests-256bits
    expiration-ms: 3600000            # 1h en test (court pour tester l'expiration)
    refresh-expiration-ms: 86400000   # 24h

# ── Logs — warnings seulement en CI ──────────────────────────────────────────
logging:
  level:
    root: WARN
    com.mbem.mbemlevel: INFO
    org.flywaydb: WARN
YMLEOF
log_ok "application-test.yaml"

# =============================================================================
# FICHIER 5 — application-prod.yaml (production VPS)
# =============================================================================
log_sec "5/6 application-prod.yaml"

cat > "$RES/application-prod.yaml" << 'YMLEOF'
# =============================================================================
# MbemNova — Profil PROD (production VPS)
# Activé par : SPRING_PROFILES_ACTIVE=prod
#
# RÈGLE ABSOLUE : Aucune valeur en dur ici.
# TOUTES les valeurs sensibles viennent des variables d'environnement.
# Utiliser .env.example comme référence → copier en .env local (jamais commité).
#
# Valeurs manquantes → l'application refusera de démarrer (fail-fast).
# =============================================================================

spring:
  # ── Base de données PostgreSQL ────────────────────────────────────────────────
  datasource:
    # Format : jdbc:postgresql://host:5432/dbname?sslmode=require
    url: ${DATABASE_URL}
    username: ${DATABASE_USERNAME}
    password: ${DATABASE_PASSWORD}
    driver-class-name: org.postgresql.Driver
    hikari:
      pool-name: HikariPool-Prod
      maximum-pool-size: ${DB_POOL_SIZE:20}
      minimum-idle: ${DB_POOL_MIN_IDLE:5}
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
      # Détecte les connexions abandonnées (fuites)
      leak-detection-threshold: 60000

  jpa:
    hibernate:
      ddl-auto: validate             # Flyway gère le schéma — validate seulement
    show-sql: false                  # Jamais de SQL en prod (performance + sécurité)

  # ── Redis avec TLS ───────────────────────────────────────────────────────────
  data:
    redis:
      host: ${REDIS_HOST}
      port: ${REDIS_PORT:6379}
      password: ${REDIS_PASSWORD}
      ssl:
        enabled: true                # TLS obligatoire en prod
      timeout: 5000ms
      lettuce:
        pool:
          max-active: 20
          max-idle: 10
          min-idle: 2

  # ── Email SMTP sécurisé ──────────────────────────────────────────────────────
  mail:
    host: ${MAIL_HOST}
    port: ${MAIL_PORT:587}
    username: ${MAIL_USERNAME}
    password: ${MAIL_PASSWORD}
    properties:
      mail.smtp.auth: true
      mail.smtp.starttls.enable: true
      mail.smtp.starttls.required: true
      mail.smtp.timeout: 10000
      mail.smtp.connectiontimeout: 10000

  thymeleaf:
    cache: true                      # Cache templates en prod (perf)

# ── Actuator sécurisé ────────────────────────────────────────────────────────
management:
  endpoints:
    web:
      exposure:
        # Exposer uniquement le nécessaire pour Prometheus et la santé
        include: health,prometheus,info
  endpoint:
    health:
      show-details: when-authorized   # Détails réservés aux admins
  tracing:
    sampling:
      probability: ${TRACING_PROBABILITY:0.05}  # 5% par défaut (configurable)

# ── Swagger DÉSACTIVÉ en prod ────────────────────────────────────────────────
springdoc:
  swagger-ui:
    enabled: false                   # JAMAIS exposer Swagger en production
  api-docs:
    enabled: false

# ── JWT — secrets depuis les variables d'environnement ───────────────────────
security:
  jwt:
    secret: ${JWT_SECRET}                                  # Min 32 chars / 256 bits
    expiration-ms: ${JWT_EXPIRATION_MS:86400000}           # 24h par défaut
    refresh-expiration-ms: ${JWT_REFRESH_MS:2592000000}    # 30j par défaut

# ── Logs structurés JSON pour ELK (Elasticsearch/Logstash) ───────────────────
logging:
  level:
    root: WARN
    com.mbem.mbemlevel: INFO
  # Les logs JSON sont configurés dans logback-spring.xml
  # (le pattern console est ignoré en prod au profit du JSON appender)
YMLEOF
log_ok "application-prod.yaml"

# =============================================================================
# FICHIER 6 — logback-spring.xml (logs structurés JSON + MDC)
# =============================================================================
log_sec "6/6 logback-spring.xml"

cat > "$RES/logback-spring.xml" << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!--
  MbemNova — Configuration Logback
  - DEV   : logs colorés lisibles sur le terminal
  - PROD  : logs JSON structurés pour collecte ELK (Logstash)
  - MDC   : requestId, userId, method, path injectés automatiquement
            par RequestLoggingFilter dans chaque ligne de log
-->
<configuration scan="true" scanPeriod="30 seconds">

  <!-- Variables de configuration -->
  <springProperty name="APP_NAME" source="spring.application.name" defaultValue="mbemlevel"/>

  <!-- ════════════════════════════════════════════════════════════════
       APPENDER DEV : Console colorée et lisible
  ════════════════════════════════════════════════════════════════ -->
  <springProfile name="dev">
    <appender name="CONSOLE_DEV" class="ch.qos.logback.core.ConsoleAppender">
      <encoder>
        <!-- Couleurs + MDC requestId + userId -->
        <pattern>%d{HH:mm:ss.SSS} %highlight(%-5level) [%cyan(%X{requestId:--})] [%yellow(%X{userId:--})] %logger{36} — %msg%n</pattern>
        <charset>UTF-8</charset>
      </encoder>
    </appender>

    <root level="INFO">
      <appender-ref ref="CONSOLE_DEV"/>
    </root>

    <logger name="com.mbem.mbemlevel" level="DEBUG" additivity="false">
      <appender-ref ref="CONSOLE_DEV"/>
    </logger>
  </springProfile>

  <!-- ════════════════════════════════════════════════════════════════
       APPENDER TEST : Minimal, sans couleurs
  ════════════════════════════════════════════════════════════════ -->
  <springProfile name="test">
    <appender name="CONSOLE_TEST" class="ch.qos.logback.core.ConsoleAppender">
      <encoder>
        <pattern>%d{HH:mm:ss} %-5level [%X{requestId:--}] %logger{36} — %msg%n</pattern>
        <charset>UTF-8</charset>
      </encoder>
    </appender>

    <root level="WARN">
      <appender-ref ref="CONSOLE_TEST"/>
    </root>

    <logger name="com.mbem.mbemlevel" level="INFO" additivity="false">
      <appender-ref ref="CONSOLE_TEST"/>
    </logger>
  </springProfile>

  <!-- ════════════════════════════════════════════════════════════════
       APPENDER PROD : JSON structuré pour ELK
       Chaque ligne de log = un objet JSON sur une seule ligne
       → parsé automatiquement par Logstash
  ════════════════════════════════════════════════════════════════ -->
  <springProfile name="prod">
    <appender name="CONSOLE_JSON" class="ch.qos.logback.core.ConsoleAppender">
      <encoder class="net.logstash.logback.encoder.LogstashEncoder">
        <!-- Champs fixes dans chaque log JSON -->
        <customFields>{"app":"${APP_NAME}"}</customFields>
        <!-- MDC automatiquement inclus (requestId, userId, method, path) -->
        <includeMdcKeyName>requestId</includeMdcKeyName>
        <includeMdcKeyName>userId</includeMdcKeyName>
        <includeMdcKeyName>method</includeMdcKeyName>
        <includeMdcKeyName>path</includeMdcKeyName>
        <includeMdcKeyName>ip</includeMdcKeyName>
        <!-- Masquer les données sensibles dans les logs -->
        <throwableConverter class="net.logstash.logback.stacktrace.ShortenedThrowableConverter">
          <maxDepthPerCause>10</maxDepthPerCause>
          <rootCauseFirst>true</rootCauseFirst>
        </throwableConverter>
      </encoder>
    </appender>

    <root level="WARN">
      <appender-ref ref="CONSOLE_JSON"/>
    </root>

    <logger name="com.mbem.mbemlevel" level="INFO" additivity="false">
      <appender-ref ref="CONSOLE_JSON"/>
    </logger>

    <!-- Alertes Flyway et sécurité toujours loggées -->
    <logger name="org.flywaydb" level="INFO"/>
    <logger name="org.springframework.security" level="WARN"/>
  </springProfile>

</configuration>
XMLEOF
log_ok "logback-spring.xml"

# =============================================================================
# RÉSUMÉ
# =============================================================================
echo ""
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo -e "${C_BOLD}${C_GREEN}  Script 01/15 terminé avec succès              ${C_NC}"
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo ""
echo -e "  ${C_GREEN}✓${C_NC}  pom.xml"
echo -e "  ${C_GREEN}✓${C_NC}  application.yaml (base commune)"
echo -e "  ${C_GREEN}✓${C_NC}  application-dev.yaml"
echo -e "  ${C_GREEN}✓${C_NC}  application-test.yaml"
echo -e "  ${C_GREEN}✓${C_NC}  application-prod.yaml"
echo -e "  ${C_GREEN}✓${C_NC}  logback-spring.xml"
echo ""
echo -e "  ${C_YELLOW}→ Prochain script : ./s02_structure.sh${C_NC}"
echo ""
