package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "avis_cours")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class AvisCoursJpaEntity {

    @Id
    private UUID id;

    @Column(name = "cours_id", nullable = false)
    private UUID coursId;

    @Column(name = "apprenant_id", nullable = false)
    private UUID apprenantId;

    @Column(nullable = false)
    private int note;

    @Column(columnDefinition = "TEXT")
    private String commentaire;

    @Column(name = "est_verifie", nullable = false)
    private boolean estVerifie;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
