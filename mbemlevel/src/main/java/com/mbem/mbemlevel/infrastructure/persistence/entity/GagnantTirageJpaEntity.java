package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "gagnants_tirage")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class GagnantTirageJpaEntity {

    @Id
    private UUID id;

    @Column(name = "tirage_id", nullable = false)
    private UUID tirageId;

    @Column(name = "apprenant_id", nullable = false)
    private UUID apprenantId;

    @Column(nullable = false)
    private int rang; // 1 = principal, 2-3 = consolation

    @Column(name = "lot_description", length = 300)
    private String lotDescription;

    @Column(nullable = false)
    private boolean notifie;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
