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
