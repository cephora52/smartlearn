package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import jakarta.persistence.Id; 
import java.util.UUID;

@Entity
@Table(name = "progression", uniqueConstraints = @UniqueConstraint(columnNames = { "apprenant_id", "cours_id" }))
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProgressionJpaEntity {
    @Id
    private UUID id;
    @Column(name = "apprenant_id", nullable = false)
    private UUID apprenantId;
    @Column(name = "cours_id", nullable = false)
    private UUID coursId;
    @Column(nullable = false)
    private double pourcentage;
    @Column(name = "est_paye", nullable = false)
    private boolean estPaye;
    @Column(name = "xp_gagne", nullable = false)
    private int xpGagne;
    @Column(name = "date_debut", nullable = false)
    private LocalDateTime dateDebut;
    @Column(name = "date_completion")
    private LocalDateTime dateCompletion;
    @Column(name = "seuil_paiement_cours", nullable = false)
    private double seuilPaiementCours;
    @Column(name = "lecons_terminees")
    private String leconsTerminees;
    @Column(name = "final_quiz_done", nullable = false)
    private boolean finalQuizDone;
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
