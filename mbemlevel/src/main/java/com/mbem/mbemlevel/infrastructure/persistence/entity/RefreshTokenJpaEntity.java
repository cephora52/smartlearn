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
