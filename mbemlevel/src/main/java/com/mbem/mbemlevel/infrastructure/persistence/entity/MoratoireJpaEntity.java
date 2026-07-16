package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import jakarta.persistence.Id;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "moratoires")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MoratoireJpaEntity {

    @Id
    private UUID id;

    @Column(name = "paiement_id", nullable = false)
    private UUID paiementId;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String raison;

    @Column(name = "nouvelle_date_souhaitee", nullable = false)
    private LocalDate nouvelleDateSouhaitee;

    @Column(name = "nouvelle_date_accordee")
    private LocalDate nouvelleDateAccordee;

    @Column(nullable = false, length = 20)
    private String statut; // EN_ATTENTE, APPROUVE, REFUSE

    @Column(name = "admin_id")
    private UUID adminId;

    @Column(name = "justification_refus", columnDefinition = "TEXT")
    private String justificationRefus;

    @Column(name = "date_decision")
    private LocalDateTime dateDecision;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
