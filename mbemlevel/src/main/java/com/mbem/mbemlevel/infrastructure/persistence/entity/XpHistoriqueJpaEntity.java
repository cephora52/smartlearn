package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "historique_xp")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class XpHistoriqueJpaEntity {
    @Id
    private UUID id;

    @Column(name = "apprenant_id", nullable = false)
    private UUID apprenantId;

    @Column(name = "xp_gagne", nullable = false)
    private int xpGagne;

    @Column(name = "date_gain", nullable = false)
    private LocalDateTime dateGain;
}
