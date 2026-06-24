package com.mbem.mbemlevel.infrastructure.persistence.entity;

import java.time.LocalDateTime;
import java.util.UUID;

import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "parrainages")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ParrainageJpaEntity {

    @Id
    private UUID id;

    @Column(name = "parrain_id", nullable = false)
    private UUID parrainId;

    @Column(name = "filleul_id")
    private UUID filleulId;

    @Column(name = "code_parrainage", nullable = false, length = 20, unique = true)
    private String codeParrainage;

    @Column(nullable = false, length = 20)
    private String statut; // EN_ATTENTE, ACTIF, RECOMPENSE_ACCORDEE

    @Column(name = "date_inscription")
    private LocalDateTime dateInscription;

    @Column(name = "date_activation")
    private LocalDateTime dateActivation;

    @Column(name = "xp_parrain_credite", nullable = false)
    private int xpParrainCredite;

    @Column(name = "xp_filleul_credite", nullable = false)
    private int xpFilleulCredite;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
