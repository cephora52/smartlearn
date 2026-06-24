package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import jakarta.persistence.Id;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "modules")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ModuleJpaEntity {

    @Id
    private UUID id;

    @Column(name = "cours_id", nullable = false)
    private UUID coursId;

    @Column(nullable = false, length = 200)
    private String titre;

    @Column(length = 500)
    private String description;

    @Column(nullable = false)
    private int ordre;

    @Column(name = "est_verrouille", nullable = false)
    private boolean estVerrouille;

    @Column(name = "xp_bonus", nullable = false)
    private int xpBonus;

    /**
     * Module entièrement gratuit — accessible avant le seuil de paiement.
     * Typiquement vrai pour le module d'introduction.
     */
    @Column(name = "est_gratuit", nullable = false)
    private boolean estGratuit;

    /** Nombre de leçons — dénormalisé pour affichage rapide */
    @Column(name = "nb_lecons", nullable = false)
    private int nbLecons;

    /** Durée totale cumulée des leçons en minutes */
    @Column(name = "duree_totale_minutes", nullable = false)
    private int dureeTotaleMinutes;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
