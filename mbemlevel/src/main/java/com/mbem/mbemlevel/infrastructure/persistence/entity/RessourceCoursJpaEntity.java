package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "ressources_cours")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class RessourceCoursJpaEntity {

    @Id
    private UUID id;

    @Column(name = "cours_id", nullable = false)
    private UUID coursId;

    @Column(name = "lecon_id")
    private UUID leconId;

    @Column(name = "type_ressource", nullable = false, length = 20)
    private String typeRessource; // PDF, IMAGE, AUDIO, ZIP, LIEN

    @Column(nullable = false, length = 200)
    private String nom;

    @Column(name = "url_stockage", nullable = false, length = 500)
    private String urlStockage;

    @Column(name = "taille_octets")
    private Long tailleOctets;

    @Column(name = "mime_type", length = 100)
    private String mimeType;

    @Column(name = "est_public", nullable = false)
    private boolean estPublic;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
