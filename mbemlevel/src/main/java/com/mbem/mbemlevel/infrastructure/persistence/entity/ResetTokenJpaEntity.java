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
