package com.mbem.mbemlevel.infrastructure.persistence.entity;

import jakarta.persistence.*;
import jakarta.persistence.Id;
import lombok.*;
import org.springframework.data.annotation.*;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entité JPA du QCM d'une leçon.
 * Options stockées en JSONB : [{"id":"A","texte":"..."},{"id":"B","texte":"..."}]
 * La bonne réponse n'est JAMAIS envoyée au front sauf après soumission.
 */
@Entity
@Table(name = "qcm")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class QCMJpaEntity {

    @Id
    private UUID id;

    @Column(name = "lecon_id", nullable = false)
    private UUID leconId;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String question;

    /**
     * JSON array des options : [{"id":"A","texte":"..."},{"id":"B","texte":"..."}]
     * Stocké en TEXT — parsé côté applicatif avec ObjectMapper.
     */
    @Column(name = "options_json", nullable = false, columnDefinition = "TEXT")
    private String optionsJson;

    /** Identifiant de la bonne réponse : "A", "B", "C" ou "D" */
    @Column(name = "bonne_reponse", nullable = false, length = 1)
    private String bonneReponse;

    /**
     * Explication affichée après soumission.
     * Ex: "La bonne réponse est B car Spring Boot gère l'IoC automatiquement."
     */
    @Column(columnDefinition = "TEXT")
    private String explication;

    @Column(name = "score_points", nullable = false)
    private int scorePoints;

    @Column(nullable = false)
    private int ordre;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
