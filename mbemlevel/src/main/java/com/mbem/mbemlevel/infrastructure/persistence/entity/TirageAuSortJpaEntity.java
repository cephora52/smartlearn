package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "tirages_au_sort")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class TirageAuSortJpaEntity {

    @Id
    private UUID id;

    @Column(nullable = false, length = 7, unique = true)
    private String mois; // YYYY-MM

    @Column(name = "nb_participants", nullable = false)
    private int nbParticipants;

    @Column(name = "formation_prix", length = 200)
    private String formationPrix;

    @Column(name = "valeur_prix")
    private Long valeurPrix;

    @Column(name = "admin_id", nullable = false)
    private UUID adminId;

    @Column(name = "effectue_le", nullable = false)
    private LocalDateTime effectueLe;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
