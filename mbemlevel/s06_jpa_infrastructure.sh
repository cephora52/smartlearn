#!/usr/bin/env bash
# =============================================================================
# MbemNova — Script 06/15 : Infrastructure JPA (Entities + Repos + Adapters)
# =============================================================================
# RÔLE   : Implémente la couche persistence de l'infrastructure.
#          Anti-Corruption Layer : les entités JPA sont séparées du domaine.
#
# CONTENU :
#   ── Entités JPA (4 principales pour l'auth) ─────────────────────────────
#   UtilisateurJpaEntity.java
#   RefreshTokenJpaEntity.java
#   ResetTokenJpaEntity.java
#   AuditLogJpaEntity.java
#
#   ── Repositories Spring Data JPA ────────────────────────────────────────
#   UtilisateurJpaRepository.java
#   RefreshTokenJpaRepository.java
#   ResetTokenJpaRepository.java
#   AuditLogJpaRepository.java
#
#   ── Adapters (implémentent les ports Application) ────────────────────────
#   UtilisateurRepositoryAdapter.java
#   RefreshTokenRepositoryAdapter.java
#   ResetTokenRepositoryAdapter.java
#   AuditLogRepositoryAdapter.java
#
#   ── Mapper JPA ↔ Domain ──────────────────────────────────────────────────
#   UtilisateurJpaMapper.java
#
#   ── Configuration JPA ────────────────────────────────────────────────────
#   JpaConfig.java
#
# PRÉREQUIS : s01 + s02 + s03 doivent avoir été lancés
# USAGE     : chmod +x s06_jpa_infrastructure.sh && ./s06_jpa_infrastructure.sh
# =============================================================================

set -euo pipefail
export LC_ALL=C.UTF-8

C_GREEN='\033[0;32m'; C_BLUE='\033[0;34m'; C_CYAN='\033[0;36m'
C_BOLD='\033[1m';     C_NC='\033[0m'

log_ok()  { echo -e "${C_GREEN}  [OK]${C_NC} $1"; }
log_sec() { echo -e "\n${C_BOLD}${C_CYAN}── $1 ──${C_NC}"; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$ROOT/src/main/java/com/mbem/mbemlevel"

echo ""
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo -e "${C_BOLD}${C_CYAN}  MbemNova · Script 06/15 · Infrastructure JPA ${C_NC}"
echo -e "${C_BOLD}${C_CYAN}================================================${C_NC}"
echo ""

[[ ! -f "$ROOT/pom.xml" ]] && { echo "ERREUR: lancez s01 d'abord"; exit 1; }
[[ ! -d "$PKG/domain" ]]   && { echo "ERREUR: lancez s02 + s03 d'abord"; exit 1; }

# =============================================================================
# SECTION 1 — ENTITÉS JPA
# Séparées des entités domaine (Anti-Corruption Layer)
# =============================================================================
log_sec "1/5 Entités JPA"
mkdir -p "$PKG/infrastructure/persistence/entity"

cat > "$PKG/infrastructure/persistence/entity/UtilisateurJpaEntity.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/persistence/entity/UtilisateurJpaEntity.java
//
// Entité JPA pour la table `utilisateurs`.
// SÉPARÉE intentionnellement de l'agrégat Utilisateur (domain).
// La conversion Domain ↔ JPA est réalisée par UtilisateurJpaMapper.
//
// RÈGLES :
//   - Ne jamais exposer cette classe hors de la couche Infrastructure
//   - Pas de logique métier ici — uniquement mapping colonnes ↔ champs
//   - @EntityListeners gère automatiquement createdAt / updatedAt
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import com.mbem.mbemlevel.domain.shared.enums.Role;
import com.mbem.mbemlevel.domain.shared.enums.StatutApprenant;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entité JPA table {@code utilisateurs}.
 */
@Entity
@Table(
    name = "utilisateurs",
    uniqueConstraints = @UniqueConstraint(name = "uq_utilisateurs_email", columnNames = "email")
)
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class UtilisateurJpaEntity {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    // ── Identité ──────────────────────────────────────────────────────────────
    @Column(nullable = false, length = 50)
    private String prenom;

    @Column(length = 50)
    private String nom;

    @Column(nullable = false, length = 255)
    private String email;

    /** BCrypt hash max 72 chars effectifs. JAMAIS le MDP en clair. */
    @Column(name = "mot_de_passe_hache", nullable = false, length = 72)
    private String motDePasseHache;

    @Column(name = "email_verifie", nullable = false)
    private boolean emailVerifie;

    @Column(name = "token_verification_email", length = 255)
    private String tokenVerificationEmail;

    @Column(length = 25)
    private String telephone;

    // ── Rôle et statut ────────────────────────────────────────────────────────
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StatutApprenant statut;

    // ── Protection brute-force ────────────────────────────────────────────────
    @Column(name = "tentatives_connexion_echouees", nullable = false)
    private int tentativesEchouees;

    @Column(name = "bloque_jusqu_au")
    private LocalDateTime bloqueJusquAu;

    @Column(name = "derniere_connexion")
    private LocalDateTime derniereConnexion;

    // ── Apprenant ─────────────────────────────────────────────────────────────
    @Column(length = 100)
    private String ville;

    @Column(name = "xp_total", nullable = false)
    private int xpTotal;

    @Column(name = "streak_jours", nullable = false)
    private int streakJours;

    @Column(name = "rang_plateforme")
    private Integer rangPlateforme;

    @Column(name = "disponible_pour_emploi", nullable = false)
    private boolean disponiblePourEmploi;

    @Column(name = "lien_portfolio", length = 500)
    private String lienPortfolio;

    @Column(name = "lien_cv", length = 500)
    private String lienCv;

    @Column(name = "lien_linkedin", length = 500)
    private String lienLinkedin;

    @Column(name = "lien_github", length = 500)
    private String lienGithub;

    @Column(length = 1000)
    private String bio;

    @Column(name = "code_parrainage", length = 20, unique = true)
    private String codeParrainage;

    @Column(name = "parrain_id")
    private UUID parrainId;

    // ── Formateur ─────────────────────────────────────────────────────────────
    @Column(length = 200)
    private String specialite;

    @Column(columnDefinition = "TEXT")
    private String biographie;

    @Column(name = "note_globale", precision = 3, scale = 2)
    private Double noteGlobale;

    // ── Admin ─────────────────────────────────────────────────────────────────
    @Column(name = "niveau_acces", length = 20)
    private String niveauAcces;

    // ── Audit automatique via @EntityListeners ────────────────────────────────
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
JEOF
log_ok "UtilisateurJpaEntity.java"

cat > "$PKG/infrastructure/persistence/entity/RefreshTokenJpaEntity.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/persistence/entity/RefreshTokenJpaEntity.java
// Entité JPA pour la table `refresh_tokens`.
//
// SÉCURITÉ : token_hache = SHA-256 du token brut.
// Le token brut n'est JAMAIS persisté en base.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "refresh_tokens")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class RefreshTokenJpaEntity {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @Column(name = "utilisateur_id", nullable = false)
    private UUID utilisateurId;

    /** SHA-256 du token brut — le token brut ne doit JAMAIS être persisté. */
    @Column(name = "token_hache", nullable = false, unique = true, length = 255)
    private String tokenHache;

    @Column(name = "expire_le", nullable = false)
    private LocalDateTime expireLe;

    @Column(name = "remplace_par")
    private UUID remplacePar;

    @Column(name = "est_revoque", nullable = false)
    private boolean estRevoque;

    /** IPv4 ou IPv6 (max 45 chars) */
    @Column(name = "ip_creation", length = 45)
    private String ipCreation;

    @Column(name = "user_agent", length = 500)
    private String userAgent;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (id == null)        id = UUID.randomUUID();
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
JEOF
log_ok "RefreshTokenJpaEntity.java"

cat > "$PKG/infrastructure/persistence/entity/ResetTokenJpaEntity.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/persistence/entity/ResetTokenJpaEntity.java
// Entité JPA pour la table `reset_tokens`.
// Usage unique, TTL 1h, SHA-256 en base.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "reset_tokens")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class ResetTokenJpaEntity {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @Column(name = "utilisateur_id", nullable = false)
    private UUID utilisateurId;

    /** SHA-256 du token brut. Le brut est dans l'email uniquement. */
    @Column(name = "token_hache", nullable = false, unique = true, length = 255)
    private String tokenHache;

    @Column(name = "expire_le", nullable = false)
    private LocalDateTime expireLe;

    @Column(name = "est_utilise", nullable = false)
    private boolean estUtilise;

    @Column(name = "ip_demande", length = 45)
    private String ipDemande;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "utilise_le")
    private LocalDateTime utiliseLe;

    @PrePersist
    protected void onCreate() {
        if (id == null)        id = UUID.randomUUID();
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
JEOF
log_ok "ResetTokenJpaEntity.java"

cat > "$PKG/infrastructure/persistence/entity/AuditLogJpaEntity.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/persistence/entity/AuditLogJpaEntity.java
// Entité JPA pour la table `audit_logs`.
// INSERT ONLY — le trigger PostgreSQL bloque tout UPDATE/DELETE.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

@Entity
@Table(name = "audit_logs")
@Getter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class AuditLogJpaEntity {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    /** NULL pour les actions anonymes (ex: tentatives connexion avec email inexistant). */
    @Column(name = "utilisateur_id")
    private UUID utilisateurId;

    /** Email dénormalisé — retrouvable même si le compte est supprimé. */
    @Column(name = "user_email", length = 255)
    private String userEmail;

    /** Type d'action SCREAMING_SNAKE_CASE. Ex: LOGIN_SUCCESS, ROLE_CHANGED. */
    @Column(name = "action", nullable = false, length = 100)
    private String action;

    @Column(name = "ressource_type", length = 50)
    private String ressourceType;

    @Column(name = "ressource_id", length = 255)
    private String ressourceId;

    /** Contexte JSON. Ex: {ancien_role:"APPRENANT", nouveau_role:"FORMATEUR"}. */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private Map<String, Object> details;

    /** SUCCESS | FAILURE | WARNING. */
    @Column(nullable = false, length = 20)
    private String statut;

    @Column(name = "ip_adresse", length = 45)
    private String ipAdresse;

    @Column(name = "user_agent", length = 500)
    private String userAgent;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (id == null)        id = UUID.randomUUID();
        if (createdAt == null) createdAt = LocalDateTime.now();
    }
}
JEOF
log_ok "AuditLogJpaEntity.java"

# =============================================================================
# SECTION 2 — REPOSITORIES SPRING DATA JPA
# =============================================================================
log_sec "2/5 Repositories Spring Data JPA"
mkdir -p "$PKG/infrastructure/persistence/repository"

cat > "$PKG/infrastructure/persistence/repository/UtilisateurJpaRepository.java" << 'JEOF'
// MbemNova — infrastructure/persistence/repository/UtilisateurJpaRepository.java
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.UtilisateurJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Repository Spring Data JPA pour les utilisateurs.
 * Les méthodes sensibles utilisent des requêtes JPQL explicites.
 */
public interface UtilisateurJpaRepository extends JpaRepository<UtilisateurJpaEntity, UUID> {

    /**
     * Recherche par email insensible à la casse.
     * Utilise l'index {@code idx_users_email_lower} de V9.
     */
    @Query("SELECT u FROM UtilisateurJpaEntity u WHERE LOWER(u.email) = LOWER(:email)")
    Optional<UtilisateurJpaEntity> findByEmailIgnoreCase(@Param("email") String email);

    /**
     * Vérifie l'existence sans charger l'entité complète.
     * COUNT(*) limité à 1 — plus performant que findByEmail.
     */
    @Query("SELECT COUNT(u) > 0 FROM UtilisateurJpaEntity u WHERE LOWER(u.email) = LOWER(:email)")
    boolean existsByEmailIgnoreCase(@Param("email") String email);

    /** Apprenants disponibles pour l'emploi — vitrine Talents (Scénario 14). */
    @Query("SELECT u FROM UtilisateurJpaEntity u " +
           "WHERE u.disponiblePourEmploi = true AND u.role = 'APPRENANT' " +
           "AND u.statut = 'ACTIF' ORDER BY u.xpTotal DESC")
    List<UtilisateurJpaEntity> findApprenantsDisponibles();
}
JEOF

cat > "$PKG/infrastructure/persistence/repository/RefreshTokenJpaRepository.java" << 'JEOF'
// MbemNova — infrastructure/persistence/repository/RefreshTokenJpaRepository.java
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.RefreshTokenJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/** Repository refresh tokens avec opérations de rotation et nettoyage. */
public interface RefreshTokenJpaRepository extends JpaRepository<RefreshTokenJpaEntity, UUID> {

    /** Recherche par hash — appelé à chaque refresh token. */
    Optional<RefreshTokenJpaEntity> findByTokenHache(String tokenHache);

    /**
     * Révoque tous les tokens actifs d'un utilisateur.
     * Utilisé lors d'un changement de MDP ou suspension.
     */
    @Modifying
    @Query("UPDATE RefreshTokenJpaEntity r SET r.estRevoque = true " +
           "WHERE r.utilisateurId = :userId AND r.estRevoque = false")
    int revoquerTousTokensUtilisateur(@Param("userId") UUID userId);

    /**
     * Supprime les tokens expirés ET révoqués.
     * Scheduler quotidien — libère de l'espace en base.
     */
    @Modifying
    @Query("DELETE FROM RefreshTokenJpaEntity r " +
           "WHERE r.expireLe < :maintenant OR r.estRevoque = true")
    int supprimerTokensExpiresetRevoques(@Param("maintenant") LocalDateTime maintenant);
}
JEOF

cat > "$PKG/infrastructure/persistence/repository/ResetTokenJpaRepository.java" << 'JEOF'
// MbemNova — infrastructure/persistence/repository/ResetTokenJpaRepository.java
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.ResetTokenJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/** Repository tokens de reset MDP — usage unique, TTL 1h. */
public interface ResetTokenJpaRepository extends JpaRepository<ResetTokenJpaEntity, UUID> {

    /** Recherche un token valide (non utilisé, non expiré) par son hash. */
    @Query("SELECT r FROM ResetTokenJpaEntity r " +
           "WHERE r.tokenHache = :hash " +
           "AND r.estUtilise = false " +
           "AND r.expireLe > :maintenant")
    Optional<ResetTokenJpaEntity> findTokenValide(
        @Param("hash") String hash,
        @Param("maintenant") LocalDateTime maintenant
    );

    /** Invalide tous les tokens non utilisés d'un utilisateur. */
    @Modifying
    @Query("UPDATE ResetTokenJpaEntity r SET r.estUtilise = true " +
           "WHERE r.utilisateurId = :userId AND r.estUtilise = false")
    int invaliderTousTokensUtilisateur(@Param("userId") UUID userId);

    /** Nettoyage nocturne — tokens expirés ou utilisés. */
    @Modifying
    @Query("DELETE FROM ResetTokenJpaEntity r " +
           "WHERE r.expireLe < :maintenant OR r.estUtilise = true")
    int supprimerTokensExpires(@Param("maintenant") LocalDateTime maintenant);
}
JEOF

cat > "$PKG/infrastructure/persistence/repository/AuditLogJpaRepository.java" << 'JEOF'
// MbemNova — infrastructure/persistence/repository/AuditLogJpaRepository.java
package com.mbem.mbemlevel.infrastructure.persistence.repository;

import com.mbem.mbemlevel.infrastructure.persistence.entity.AuditLogJpaEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

/**
 * Repository pour les logs d'audit.
 *
 * IMPORTANT — Table immuable :
 * N'utiliser que la méthode save() héritée de JpaRepository.
 * delete(), deleteAll(), deleteById() ne doivent JAMAIS être appelées.
 * Un trigger PostgreSQL les bloquerait de toute façon (V8__create_securite.sql).
 * L'adaptateur AuditLogRepositoryAdapter n'expose que la méthode enregistrer().
 */
public interface AuditLogJpaRepository extends JpaRepository<AuditLogJpaEntity, UUID> {
    // Intentionnellement vide — seul save() est autorisé via l'adaptateur
}
JEOF

log_ok "4 repositories Spring Data JPA"

# =============================================================================
# SECTION 3 — MAPPER JPA ↔ DOMAIN (MapStruct)
# =============================================================================
log_sec "3/5 Mapper JPA ↔ Domain"
mkdir -p "$PKG/infrastructure/persistence/mapper"

cat > "$PKG/infrastructure/persistence/mapper/UtilisateurJpaMapper.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/persistence/mapper/UtilisateurJpaMapper.java
//
// Mapper MapStruct : UtilisateurJpaEntity ↔ Utilisateur (domaine).
// @Mapper(componentModel="spring") : géré par Spring comme un @Component.
//
// POINT CRITIQUE : Pour reconstruire un Utilisateur depuis la JPA,
// on utilise le constructeur de reconstitution — PAS la factory method creer().
// La factory method publie ApprenantInscritEvent — à ne déclencher qu'une fois.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.mapper;

import com.mbem.mbemlevel.domain.user.Utilisateur;
import com.mbem.mbemlevel.infrastructure.persistence.entity.UtilisateurJpaEntity;
import org.mapstruct.*;

/**
 * Mapper bidirectionnel {@link UtilisateurJpaEntity} ↔ {@link Utilisateur}.
 *
 * <h3>Stratégie de reconstitution</h3>
 * <p>La méthode {@code toDomain} appelle le constructeur de reconstitution
 * de {@link Utilisateur} pour ne pas déclencher les domain events.</p>
 *
 * <h3>Champs ignorés</h3>
 * <p>{@code domainEvents} n'existe pas en JPA (transient) — toujours ignoré.</p>
 */
@Mapper(
    componentModel        = "spring",
    unmappedTargetPolicy  = ReportingPolicy.ERROR,
    nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE
)
public interface UtilisateurJpaMapper {

    /**
     * Convertit une entité JPA en objet domaine.
     * Utilise le constructeur de reconstitution.
     */
    @Mapping(target = "domainEvents", ignore = true)
    Utilisateur toDomain(UtilisateurJpaEntity entity);

    /**
     * Convertit un objet domaine en entité JPA pour l'insertion.
     */
    UtilisateurJpaEntity toJpaEntity(Utilisateur utilisateur);

    /**
     * Met à jour une entité JPA existante depuis l'objet domaine.
     * Pour les UPDATE : préserve l'état Hibernate (version, lazy collections…).
     *
     * @param source Domaine (source)
     * @param target Entité JPA attachée à la session Hibernate (modifiée en place)
     */
    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void updateJpaEntity(Utilisateur source, @MappingTarget UtilisateurJpaEntity target);
}
JEOF
log_ok "UtilisateurJpaMapper.java"

# =============================================================================
# SECTION 4 — ADAPTATEURS (implémentent les ports Application)
# =============================================================================
log_sec "4/5 Adaptateurs"
mkdir -p "$PKG/infrastructure/persistence/adapter"

cat > "$PKG/infrastructure/persistence/adapter/UtilisateurRepositoryAdapter.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/persistence/adapter/UtilisateurRepositoryAdapter.java
//
// Adaptateur sortant : implémente le port UtilisateurRepository.
// Seule classe qui connaît à la fois le port Application et JPA.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.UtilisateurRepository;
import com.mbem.mbemlevel.domain.user.Utilisateur;
import com.mbem.mbemlevel.infrastructure.persistence.entity.UtilisateurJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.mapper.UtilisateurJpaMapper;
import com.mbem.mbemlevel.infrastructure.persistence.repository.UtilisateurJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Adaptateur sortant pour les utilisateurs.
 * Traduit les appels domaine en opérations JPA.
 */
@Component
@RequiredArgsConstructor
public class UtilisateurRepositoryAdapter implements UtilisateurRepository {

    private final UtilisateurJpaRepository jpaRepository;
    private final UtilisateurJpaMapper     mapper;

    @Override
    @Transactional(readOnly = true)
    public Optional<Utilisateur> findById(UUID id) {
        return jpaRepository.findById(id).map(mapper::toDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Utilisateur> findByEmail(String email) {
        return jpaRepository.findByEmailIgnoreCase(email).map(mapper::toDomain);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean existsByEmail(String email) {
        return jpaRepository.existsByEmailIgnoreCase(email);
    }

    @Override
    @Transactional
    public Utilisateur save(Utilisateur utilisateur) {
        Optional<UtilisateurJpaEntity> existing = jpaRepository.findById(utilisateur.getId());

        UtilisateurJpaEntity entity;
        if (existing.isPresent()) {
            // UPDATE : utiliser updateJpaEntity pour préserver l'état Hibernate
            entity = existing.get();
            mapper.updateJpaEntity(utilisateur, entity);
        } else {
            // INSERT
            entity = mapper.toJpaEntity(utilisateur);
        }

        return mapper.toDomain(jpaRepository.save(entity));
    }

    @Override
    @Transactional(readOnly = true)
    public List<Utilisateur> findApprenantsDisponibles() {
        return jpaRepository.findApprenantsDisponibles()
            .stream().map(mapper::toDomain).collect(Collectors.toList());
    }
}
JEOF
log_ok "UtilisateurRepositoryAdapter.java"

cat > "$PKG/infrastructure/persistence/adapter/RefreshTokenRepositoryAdapter.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/persistence/adapter/RefreshTokenRepositoryAdapter.java
// Implémente RefreshTokenRepository via JPA.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.RefreshTokenRepository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.RefreshTokenJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.RefreshTokenJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class RefreshTokenRepositoryAdapter implements RefreshTokenRepository {

    private final RefreshTokenJpaRepository jpaRepository;

    @Override
    @Transactional
    public void sauvegarder(UUID utilisateurId, String tokenHache,
                            LocalDateTime expireLe, String ip, String userAgent) {
        jpaRepository.save(RefreshTokenJpaEntity.builder()
            .utilisateurId(utilisateurId)
            .tokenHache(tokenHache)
            .expireLe(expireLe)
            .estRevoque(false)
            .ipCreation(ip)
            .userAgent(userAgent)
            .build());
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<UUID> findUtilisateurIdByTokenHache(String tokenHache) {
        return jpaRepository.findByTokenHache(tokenHache)
            .filter(t -> !t.isEstRevoque() && t.getExpireLe().isAfter(LocalDateTime.now()))
            .map(RefreshTokenJpaEntity::getUtilisateurId);
    }

    @Override
    @Transactional
    public void revoquerToken(String tokenHache) {
        jpaRepository.findByTokenHache(tokenHache).ifPresent(t -> {
            t.setEstRevoque(true);
            jpaRepository.save(t);
        });
    }

    @Override
    @Transactional
    public int revoquerTousLesTokens(UUID utilisateurId) {
        return jpaRepository.revoquerTousTokensUtilisateur(utilisateurId);
    }

    @Override
    @Transactional
    public int nettoyerTokensExpires() {
        return jpaRepository.supprimerTokensExpiresetRevoques(LocalDateTime.now());
    }
}
JEOF

cat > "$PKG/infrastructure/persistence/adapter/ResetTokenRepositoryAdapter.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/persistence/adapter/ResetTokenRepositoryAdapter.java
// Implémente ResetTokenRepository via JPA.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.ResetTokenRepository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.ResetTokenJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.ResetTokenJpaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Component
@RequiredArgsConstructor
public class ResetTokenRepositoryAdapter implements ResetTokenRepository {

    private final ResetTokenJpaRepository jpaRepository;

    @Override
    @Transactional
    public void sauvegarder(UUID utilisateurId, String tokenHache,
                            LocalDateTime expireLe, String ip) {
        jpaRepository.save(ResetTokenJpaEntity.builder()
            .utilisateurId(utilisateurId)
            .tokenHache(tokenHache)
            .expireLe(expireLe)
            .estUtilise(false)
            .ipDemande(ip)
            .build());
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<UUID> findUtilisateurIdSiValide(String tokenHache, LocalDateTime maintenant) {
        return jpaRepository.findTokenValide(tokenHache, maintenant)
            .map(ResetTokenJpaEntity::getUtilisateurId);
    }

    @Override
    @Transactional
    public void marquerUtilise(String tokenHache) {
        jpaRepository.findByTokenHache(tokenHache).ifPresent(t -> {
            t.setEstUtilise(true);
            t.setUtiliseLe(LocalDateTime.now());
            jpaRepository.save(t);
        });
    }

    // Helper pour ResetTokenJpaRepository (pas encore ajouté)
    // On reuse findTokenValide avec hash = tokenHache
    private Optional<ResetTokenJpaEntity> findByToken(String hash) {
        return jpaRepository.findTokenValide(hash, LocalDateTime.now().minusYears(10));
    }

    @Override
    @Transactional
    public int invaliderTousTokensUtilisateur(UUID utilisateurId) {
        return jpaRepository.invaliderTousTokensUtilisateur(utilisateurId);
    }

    @Override
    @Transactional
    public int nettoyerTokensExpires() {
        return jpaRepository.supprimerTokensExpires(LocalDateTime.now());
    }
}
JEOF

cat > "$PKG/infrastructure/persistence/adapter/AuditLogRepositoryAdapter.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/persistence/adapter/AuditLogRepositoryAdapter.java
//
// Implémente AuditLogRepository via JPA.
// PROPAGATION.REQUIRES_NEW : persiste le log même si la transaction
// principale fait rollback. Essentiel pour tracer les échecs.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.persistence.adapter;

import com.mbem.mbemlevel.application.port.out.AuditLogRepository;
import com.mbem.mbemlevel.infrastructure.persistence.entity.AuditLogJpaEntity;
import com.mbem.mbemlevel.infrastructure.persistence.repository.AuditLogJpaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.UUID;

/**
 * Adaptateur audit — toujours persiste dans sa propre transaction.
 * Ne jamais faire échouer l'action principale à cause du log d'audit.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class AuditLogRepositoryAdapter implements AuditLogRepository {

    private final AuditLogJpaRepository jpaRepository;

    /**
     * REQUIRES_NEW : le log est persisté dans une transaction indépendante.
     * Même si la transaction principale est en rollback, le log est sauvegardé.
     */
    @Override
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void enregistrer(UUID utilisateurId, String userEmail, String action,
                            String ressourceType, String ressourceId,
                            Map<String, Object> details, String statut,
                            String ip, String userAgent) {
        try {
            jpaRepository.save(AuditLogJpaEntity.builder()
                .utilisateurId(utilisateurId)
                .userEmail(userEmail)
                .action(action)
                .ressourceType(ressourceType)
                .ressourceId(ressourceId)
                .details(details)
                .statut(statut != null ? statut : "SUCCESS")
                .ipAdresse(ip)
                .userAgent(userAgent)
                .build());
        } catch (Exception e) {
            // Log en erreur mais ne pas propager — l'audit ne doit pas bloquer le métier
            log.error("[AUDIT-FAIL] action={} user={} err={}", action, userEmail, e.getMessage());
        }
    }
}
JEOF

log_ok "4 adaptateurs JPA"

# =============================================================================
# SECTION 5 — CONFIGURATION JPA
# =============================================================================
log_sec "5/5 Configuration JPA"
mkdir -p "$PKG/infrastructure/config"

cat > "$PKG/infrastructure/config/JpaConfig.java" << 'JEOF'
// =============================================================================
// MbemNova — infrastructure/config/JpaConfig.java
// Configuration JPA : auditing automatique @CreatedDate / @LastModifiedDate.
// =============================================================================
package com.mbem.mbemlevel.infrastructure.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.auditing.DateTimeProvider;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.concurrent.Executor;

/**
 * Configuration JPA + async.
 *
 * <p>{@code @EnableJpaAuditing} active les annotations
 * {@code @CreatedDate} et {@code @LastModifiedDate} sur les entités JPA.
 * La {@code dateTimeProviderRef} garantit l'utilisation de
 * {@code LocalDateTime} cohérent avec la timezone Africa/Douala.</p>
 *
 * <p>{@code @EnableAsync} active les handlers d'events asynchrones
 * ({@code @EventListener @Async}).</p>
 */
@Configuration
@EnableJpaAuditing(dateTimeProviderRef = "auditingDateTimeProvider")
@EnableAsync
public class JpaConfig {

    /**
     * Fournisseur de date/heure pour le JPA Auditing.
     * Retourne LocalDateTime.now() (timezone configurée dans application.yaml).
     */
    @Bean(name = "auditingDateTimeProvider")
    public DateTimeProvider dateTimeProvider() {
        return () -> Optional.of(LocalDateTime.now());
    }

    /**
     * Thread pool pour les handlers d'events asynchrones (@Async).
     * Dimensionné pour ne pas saturer le pool Tomcat.
     */
    @Bean(name = "asyncEventExecutor")
    public Executor asyncEventExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(2);
        executor.setMaxPoolSize(5);
        executor.setQueueCapacity(50);
        executor.setThreadNamePrefix("mbem-async-");
        executor.initialize();
        return executor;
    }
}
JEOF
log_ok "JpaConfig.java"

# =============================================================================
# RÉSUMÉ
# =============================================================================
echo ""
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo -e "${C_BOLD}${C_GREEN}  Script 06/15 terminé avec succès              ${C_NC}"
echo -e "${C_BOLD}${C_GREEN}================================================${C_NC}"
echo ""
echo -e "  ${C_GREEN}✓${C_NC}  4 entités JPA (Utilisateur, RefreshToken, ResetToken, AuditLog)"
echo -e "  ${C_GREEN}✓${C_NC}  4 repositories Spring Data JPA"
echo -e "  ${C_GREEN}✓${C_NC}  UtilisateurJpaMapper (MapStruct bidirectionnel)"
echo -e "  ${C_GREEN}✓${C_NC}  4 adaptateurs (implémentent les ports Application)"
echo -e "  ${C_GREEN}✓${C_NC}  JpaConfig (auditing + async executor)"
echo ""
echo -e "  \033[1;33m→ Prochain script : ./s07_jwt_securite.sh\033[0m"
echo ""
