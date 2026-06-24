package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import jakarta.persistence.Id;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "sessions")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SessionJpaEntity {

    @Id
    private UUID id;

    @Column(name = "cours_id", nullable = false)
    private UUID coursId;

    @Column(name = "formateur_id", nullable = false)
    private UUID formateurId;

    @Column(nullable = false, length = 20)
    private String modalite; // PRESENTIEL | MEET

    /**
     * Lieu physique si PRESENTIEL, lien Google Meet si MEET.
     * Remplace les deux colonnes séparées lien_reunion + lieu.
     */
    @Column(name = "lieu_ou_lien", length = 300)
    private String lieuOuLien;

    @Column(name = "date_debut", nullable = false)
    private LocalDateTime dateDebut;

    @Column(name = "date_fin", nullable = false)
    private LocalDateTime dateFin;

    @Column(name = "capacite_max", nullable = false)
    private int capaciteMax;

    @Column(name = "places_disponibles", nullable = false)
    private int placesDisponibles;

    @Column(name = "nb_inscrits", nullable = false)
    private int nbInscrits;

    @Column(nullable = false, length = 200)
    private String titre;

    @Column(name = "lien_reunion", length = 300)
    private String lienReunion;

    @Column(length = 200)
    private String lieu;

    @Column(name = "est_active", nullable = false)
    private boolean estActive;

    /**
     * Statut de la session :
     * PLANIFIEE → EN_COURS → TERMINEE | ANNULEE
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
