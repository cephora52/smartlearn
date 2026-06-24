package com.mbem.mbemlevel.infrastructure.persistence.entity;

import java.time.LocalDateTime;
import java.util.UUID;

import org.springframework.data.annotation.CreatedDate;
import jakarta.persistence.Id; 
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "devoirs")
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DevoirJpaEntity {
    @Id
    private UUID id;
    @Column(name = "session_id", nullable = false)
    private UUID sessionId;
    @Column(name = "module_id")
    private UUID moduleId;
    @Column(nullable = false, length = 200)
    private String titre;
    @Column(nullable = false, columnDefinition = "TEXT")
    private String consignes;
    @Column(name = "date_remise", nullable = false)
    private LocalDateTime dateRemise;
    @Column(name = "est_verrouille", nullable = false)
    private boolean estVerrouille;
    @Column(name = "lien_ressources", length = 500)
    private String lienRessources;
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
