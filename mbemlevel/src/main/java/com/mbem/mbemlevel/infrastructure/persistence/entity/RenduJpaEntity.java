package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import jakarta.persistence.Id;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "rendus",
    uniqueConstraints = @UniqueConstraint(columnNames = {"devoir_id", "apprenant_id"}))
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RenduJpaEntity {

    @Id
    private UUID id;

    @Column(name = "devoir_id", nullable = false)
    private UUID devoirId;

    @Column(name = "apprenant_id", nullable = false)
    private UUID apprenantId;

    @Column(columnDefinition = "TEXT")
    private String contenu;

    @Column(name = "lien_fichier", length = 500)
    private String lienFichier;

    /** Note attribuée par le formateur (0-20) */
    private Integer note;

    @Column(columnDefinition = "TEXT")
    private String commentaire;

    @Column(name = "date_soumission", nullable = false)
    private LocalDateTime dateSoumission;

    @Column(name = "date_correction")
    private LocalDateTime dateCorrection;

    /**
     * Soumis après la date limite du devoir.
     * Calculé et stocké lors de la soumission pour éviter
     * une jointure avec la table devoirs à chaque lecture.
     */
    @Column(name = "en_retard", nullable = false)
    private boolean enRetard;

    /**
     * SOUMIS | EN_CORRECTION | CORRIGE
     */
    @Column(nullable = false, length = 20)
    private String statut;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
